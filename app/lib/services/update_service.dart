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
  static Future<UpdateCheckResult> check(
      {required String currentVersion}) async {
    try {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(kUpdateManifestUrl));
      final res = await req.close();
      if (res.statusCode != 200) {
        return const UpdateCheckResult(reachable: false);
      }
      final body = await res.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
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
    } catch (e) {
      LogService.warning('Update check failed: $e');
      return const UpdateCheckResult(reachable: false);
    }
  }

  /// Downloads the update zip and verifies its sha256.
  /// Returns the verified zip path, or null on failure.
  static Future<File?> downloadAndVerify(UpdateInfo info) async {
    try {
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
      if (info.sha256.isNotEmpty) {
        final bytes = await zip.readAsBytes();
        final digest = sha256Of(bytes);
        if (digest != info.sha256.toLowerCase()) {
          LogService.error('Update zip hash mismatch');
          await zip.delete();
          return null;
        }
      }
      return zip;
    } catch (e) {
      LogService.error('Update download failed: $e');
      return null;
    }
  }

  /// Extracts the zip next to itself and returns the folder.
  static Future<Directory?> extract(File zip) async {
    try {
      final bytes = await zip.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final out = Directory('${zip.parent.path}/${zip.uri.pathSegments.last}_extracted');
      if (await out.exists()) await out.delete(recursive: true);
      await out.create(recursive: true);
      for (final entry in archive) {
        final dest = File('${out.path}/${entry.name}');
        if (entry.isFile) {
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
    await File('${dir.path}/pending-version').writeAsString('$version\n$sha256');
  }

  /// Removes the pending marker after the swap handoff is spawned.
  static Future<void> clearPending() async {
    final dir = await downloadsDir();
    final marker = File('${dir.path}/pending-version');
    if (await marker.exists()) await marker.delete();
  }

  /// Spawns the handoff that swaps the new files in and relaunches.
  /// Only the app's restart click calls this — never app close.
  static Future<void> applyStaged(
      Directory extracted, File zip, String currentExePath) async {
    // The zip ships a questload/ folder — swap from inside it.
    final inner =
        Directory('${extracted.path}${Platform.pathSeparator}questload');
    final src = await inner.exists() ? inner.path : extracted.path;
    final newExe = File('$src${Platform.pathSeparator}questload.exe');
    final installDir = File(currentExePath).parent.path;
    final script = '''
\$exe = "$currentExePath"
\$new = "$newExe"
\$src = "$src"
\$dest = "$installDir"
while (Get-Process -Name questload -ErrorAction SilentlyContinue) { Start-Sleep -Milliseconds 400 }
try {
  Copy-Item -Recurse -Force (Join-Path \$src '*') \$dest -ErrorAction Stop
  Remove-Item -Recurse -Force \$src
  Start-Process (Join-Path \$dest 'questload.exe')
} catch {
  \$e = "Copy-Item -Recurse -Force (Join-Path '\$src' '*') '\$dest'; Remove-Item -Recurse -Force '\$src'; Start-Process (Join-Path '\$dest' 'questload.exe')"
  Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -Command", \$e
}
''';
    final scriptFile = File('${zip.parent.path}/apply.ps1');
    await scriptFile.writeAsString(script);
    // Detached: the app exits right after, the script keeps running.
    Process.start(
      'powershell',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', scriptFile.path],
      mode: ProcessStartMode.detached,
    );
  }

  /// Reads the embedded changelog shipped with this build.
  static Future<String> embeddedChangelog(String currentExePath) async {
    final file = File(
        '${File(currentExePath).parent.path}${Platform.pathSeparator}$kChangelogFileName');
    if (!await file.exists()) return '';
    return file.readAsString();
  }
}

String sha256Of(List<int> bytes) =>
    sha256.convert(bytes).toString().toLowerCase();
