import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import '../core/constants.dart';
import 'log_service.dart';
import 'paths_service.dart';

/// What a newer version looks like, from the release manifest.
class UpdateInfo {
  final String version;
  final String sha256;
  final String zipUrl;
  final String zipName;

  const UpdateInfo({
    required this.version,
    required this.sha256,
    required this.zipUrl,
    required this.zipName,
  });
}

/// Result of an update check: the found update (if any) and whether the
/// update server was reachable at all. "No update" and "couldn't check"
/// are different things and should not be shown as the same message.
class UpdateCheckResult {
  final UpdateInfo? info;
  final bool reachable;

  const UpdateCheckResult({this.info, required this.reachable});
}

/// Compares date versions like 26.8.16 and 26.8.16-1.
/// Returns <0 when a is older, 0 when equal, >0 when newer.
int compareVersions(String a, String b) {
  int base(String v) {
    final d = v.split('-').first.split('.');
    final parts = d.map((p) => int.tryParse(p) ?? 0).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts[0] * 10000 + parts[1] * 100 + parts[2];
  }

  int order(String v) {
    final parts = v.split('-');
    return parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  }

  final b1 = base(a), b2 = base(b);
  if (b1 != b2) return b1.compareTo(b2);
  return order(a).compareTo(order(b));
}

/// Update check + download + apply, Windows only for the apply part.
class UpdateService {
  /// Downloads directory (app data root, next to settings.json).
  static Future<Directory> downloadsDir() async {
    final root = await PathsService.root;
    final dir = Directory('$root/downloads');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Asks the release manifest whether a newer version exists.
  /// Supports both the old direct manifest (version/sha256/zip_url) and the
  /// GitHub releases/latest API (tag_name + assets containing manifest.json).
  static Future<UpdateCheckResult> check({
    required String currentVersion,
  }) async {
    try {
      final client = HttpClient();
      // 1. Fetch release json (GitHub) or raw manifest (legacy).
      final req = await client.getUrl(Uri.parse(kUpdateManifestUrl));
      // GitHub API needs a UA or it 403s.
      req.headers.set('User-Agent', 'QuestLoad');
      req.headers.set('Accept', 'application/vnd.github+json');
      final res = await req.close();
      if (res.statusCode != 200) {
        return const UpdateCheckResult(reachable: false);
      }
      final body = await res.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      // If this already looks like a raw manifest, use it directly.
      if (data.containsKey('version')) {
        final version = data['version'] as String?;
        if (version == null || compareVersions(version, currentVersion) <= 0) {
          return const UpdateCheckResult(reachable: true);
        }
        return UpdateCheckResult(
          reachable: true,
          info: UpdateInfo(
            version: version,
            sha256: (data['sha256'] as String?) ?? '',
            zipUrl: (data['zip_url'] as String?) ?? '',
            zipName: (data['zip'] as String?) ?? 'questload-$version.zip',
          ),
        );
      }

      // GitHub release: try manifest.json asset first.
      final assets = (data['assets'] as List?) ?? const [];
      Map<String, dynamic>? manifest;
      String? manifestUrl;
      for (final a in assets) {
        if (a is Map && (a['name'] as String?) == 'manifest.json') {
          manifestUrl = a['browser_download_url'] as String?;
          break;
        }
      }
      if (manifestUrl != null) {
        try {
          final mReq = await client.getUrl(Uri.parse(manifestUrl));
          mReq.headers.set('User-Agent', 'QuestLoad');
          final mRes = await mReq.close();
          if (mRes.statusCode == 200) {
            final mBody = await mRes.transform(utf8.decoder).join();
            manifest = jsonDecode(mBody) as Map<String, dynamic>;
          }
        } catch (_) {}
      }
      if (manifest != null && manifest.containsKey('version')) {
        final version = manifest['version'] as String?;
        if (version == null || compareVersions(version, currentVersion) <= 0) {
          return const UpdateCheckResult(reachable: true);
        }
        return UpdateCheckResult(
          reachable: true,
          info: UpdateInfo(
            version: version,
            sha256: (manifest['sha256'] as String?) ?? '',
            zipUrl: (manifest['zip_url'] as String?) ?? '',
            zipName: (manifest['zip'] as String?) ?? 'questload-$version.zip',
          ),
        );
      }

      // Fallback: use tag_name + zip asset directly (no sha -> not verifiable, so skip).
      final tag = (data['tag_name'] as String?)?.replaceFirst(RegExp(r'^v'), '');
      if (tag == null || compareVersions(tag, currentVersion) <= 0) {
        return const UpdateCheckResult(reachable: true);
      }
      // Find a questload-*.zip asset to offer, but without sha256 we can't verify — report reachable with no info so UI shows "check succeeded, no verified update".
      return const UpdateCheckResult(reachable: true);
    } catch (e) {
      LogService.warning('Update check failed: $e');
      return const UpdateCheckResult(reachable: false);
    }
  }

  /// Downloads the update zip and verifies its sha256.
  /// Returns the verified zip path, or null on failure.
  /// The manifest must include a sha256 — unverified zips are rejected.
  static Future<File?> downloadAndVerify(UpdateInfo info) async {
    try {
      if (info.sha256.isEmpty) {
        LogService.error('Update manifest missing sha256');
        return null;
      }
      final dir = await downloadsDir();
      final zip = File('${dir.path}/${info.zipName}');
      if (info.zipUrl.isNotEmpty) {
        final client = HttpClient();
        final req = await client.getUrl(Uri.parse(info.zipUrl));
        final res = await req.close();
        if (res.statusCode != 200) return null;
        final sink = zip.openWrite();
        await res.pipe(sink);
        await sink.close();
      }
      final bytes = await zip.readAsBytes();
      final digest = sha256Of(bytes);
      if (digest != info.sha256.toLowerCase()) {
        LogService.error('Update zip hash mismatch');
        await zip.delete();
        return null;
      }
      return zip;
    } catch (e) {
      LogService.error('Update download failed: $e');
      return null;
    }
  }

  /// Extracts the zip next to itself and returns the folder.
  /// Entries must be relative paths without `..` — anything else is skipped.
  static Future<Directory?> extract(File zip) async {
    try {
      final bytes = await zip.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final out = Directory(
        '${zip.parent.path}/${zip.uri.pathSegments.last}_extracted',
      );
      if (await out.exists()) await out.delete(recursive: true);
      await out.create(recursive: true);
      for (final entry in archive) {
        final name = entry.name.replaceAll('\\', '/');
        final parts = name.split('/');
        if (name.startsWith('/') || parts.contains('..') || parts.isEmpty) {
          LogService.error('Skipping unsafe zip entry: ${entry.name}');
          continue;
        }
        if (entry.isFile) {
          final dest = File('${out.path}/$name');
          await dest.create(recursive: true);
          await dest.writeAsBytes(entry.content as List<int>);
        }
      }
      return out;
    } catch (e) {
      LogService.error('Update extract failed: $e');
      return null;
    }
  }

  /// True when a staged update from a previous run is waiting to be applied.
  static Future<bool> hasStagedUpdate(String currentVersion) async {
    final pending = await pendingInfo();
    return pending != null &&
        compareVersions(pending.version, currentVersion) > 0;
  }

  /// (version, sha256) of the downloaded-but-unapplied update, if any.
  static Future<({String version, String sha256})?> pendingInfo() async {
    final dir = await downloadsDir();
    final marker = File('${dir.path}/pending-version');
    if (!await marker.exists()) return null;
    final lines = (await marker.readAsString()).split('\n');
    if (lines.isEmpty || lines[0].trim().isEmpty) return null;
    return (
      version: lines[0].trim(),
      sha256: lines.length > 1 ? lines[1].trim() : '',
    );
  }

  /// Marks an update as pending so the next launch asks to apply it.
  static Future<void> markPending(String version, String sha256) async {
    final dir = await downloadsDir();
    await File(
      '${dir.path}/pending-version',
    ).writeAsString('$version\n$sha256');
  }

  /// Removes the pending marker after the swap handoff is spawned.
  static Future<void> clearPending() async {
    final dir = await downloadsDir();
    final marker = File('${dir.path}/pending-version');
    if (await marker.exists()) await marker.delete();
  }

  static String _appDirFor(String exePath) {
    final exeDir = File(exePath).parent;
    final base = exeDir.path.split(Platform.pathSeparator).last;
    if (base == 'qlapp') return exeDir.path;
    // Root launcher launching — real app lives in qlapp subdir.
    final qlapp = Directory('${exeDir.path}${Platform.pathSeparator}qlapp');
    if (qlapp.existsSync()) return qlapp.path;
    return exeDir.path; // old flat layout fallback
  }

  /// Spawns the handoff that swaps the new files in and relaunches.
  /// Only the app's restart click calls this — never app close.
  /// Returns false when the handoff couldn't launch — the caller must
  /// NOT exit the app in that case.
  static Future<bool> applyStaged(
    Directory extracted,
    File zip,
    String currentExePath,
  ) async {
    // Zip may ship qlapp/ (new) or questload/ (old) or flat files.
    final qlappInner = Directory(
      '${extracted.path}${Platform.pathSeparator}qlapp',
    );
    final questloadInner = Directory(
      '${extracted.path}${Platform.pathSeparator}questload',
    );
    String src;
    if (await qlappInner.exists()) {
      src = qlappInner.path;
    } else if (await questloadInner.exists()) {
      src = questloadInner.path;
    } else {
      src = extracted.path;
    }
    final installDir = _appDirFor(currentExePath);
    // Paths sit in single-quoted PS literals: a quote or dollar in the
    // install dir can't alter the script. If the swap hits a permission
    // wall the script re-runs itself elevated (UAC) — no string building.
    String psLiteral(String s) => "'${s.replaceAll("'", "''")}'";
    final script =
        '''
\$src = ${psLiteral(src)}
\$dest = ${psLiteral(installDir)}
\$script = \$PSCommandPath
while (Get-Process -Name questload -ErrorAction SilentlyContinue) { Start-Sleep -Milliseconds 400 }
try {
  Copy-Item -Recurse -Force (Join-Path \$src '*') \$dest -ErrorAction Stop
  Remove-Item -Recurse -Force \$src
  Start-Process (Join-Path \$dest 'questload.exe')
} catch {
  Remove-Item -Recurse -Force \$src
  Start-Process powershell -Verb RunAs -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "' + \$script + '"')
}
''';
    final scriptFile = File('${zip.parent.path}/apply.ps1');
    await scriptFile.writeAsString(script);
    // Await the spawn — exiting before it finishes kills the handoff
    // before it ever runs.
    try {
      await Process.start('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        scriptFile.path,
      ], mode: ProcessStartMode.detached);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      LogService.error('Update handoff failed to start: $e');
      return false;
    }
  }

  /// Reads the embedded changelog shipped with this build.
  /// New layout: qlapp/CHANGELOG.md, old: next to exe. Launcher case: sibling qlapp/CHANGELOG.md.
  static Future<String> embeddedChangelog(String currentExePath) async {
    final exeDir = File(currentExePath).parent;
    final candidates = <String>[
      '${exeDir.path}${Platform.pathSeparator}$kChangelogFileName',
      '${exeDir.path}${Platform.pathSeparator}qlapp${Platform.pathSeparator}$kChangelogFileName',
      '${_appDirFor(currentExePath)}${Platform.pathSeparator}$kChangelogFileName',
    ];
    for (final p in candidates) {
      final f = File(p);
      if (await f.exists()) return f.readAsString();
    }
    return '';
  }
}

String sha256Of(List<int> bytes) =>
    sha256.convert(bytes).toString().toLowerCase();
