import 'dart:convert';
import 'dart:io';

// QuestLoad root launcher / installer.
// - If qlapp/questload.exe exists next to this exe, just forward to it.
// - Otherwise behaves as installer: fetches latest questload-*.zip from
//   GitHub releases, extracts to qlapp/, then launches.
// No external packages, only dart:io + powershell for zip.
Future<void> main(List<String> args) async {
  final exe = Platform.resolvedExecutable;
  final exeDir = File(exe).parent;
  final isQlapp = exeDir.path.split(Platform.pathSeparator).last == 'qlapp';
  // Installed layout: exe at root, app at root/qlapp/questload.exe
  // If somehow this launcher *is* inside qlapp, just exec sibling.
  String qlappExe;
  String installRoot;
  if (isQlapp) {
    qlappExe = '${exeDir.path}${Platform.pathSeparator}questload.exe';
    installRoot = exeDir.parent.path;
  } else {
    qlappExe = '${exeDir.path}${Platform.pathSeparator}qlapp${Platform.pathSeparator}questload.exe';
    installRoot = exeDir.path;
  }

  final appFile = File(qlappExe);
  if (await appFile.exists()) {
    // Forward.
    try {
      await Process.start(qlappExe, args, mode: ProcessStartMode.detached);
    } catch (e) {
      stderr.writeln('Failed to launch $qlappExe: $e');
      exit(1);
    }
    exit(0);
  }

  // Installer mode — no qlapp yet.
  stdout.writeln('QuestLoad not installed — fetching latest release...');
  const api = 'https://api.github.com/repos/mrrewilh/questload/releases/latest';
  try {
    final client = HttpClient();
    final req = await client.getUrl(Uri.parse(api));
    req.headers.set('User-Agent', 'QuestLoad-Launcher');
    req.headers.set('Accept', 'application/vnd.github+json');
    final res = await req.close();
    if (res.statusCode != 200) {
      stderr.writeln('Release check failed: HTTP ${res.statusCode}');
      exit(1);
    }
    final body = await res.transform(utf8.decoder).join();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final assets = (data['assets'] as List?) ?? [];
    String? zipUrl;
    String? zipName;
    for (final a in assets) {
      if (a is Map) {
        final n = a['name'] as String?;
        if (n != null && n.startsWith('questload-') && n.endsWith('.zip')) {
          zipUrl = a['browser_download_url'] as String?;
          zipName = n;
          break;
        }
      }
    }
    if (zipUrl == null) {
      stderr.writeln('No questload zip found in latest release.');
      exit(1);
    }
    stdout.writeln('Downloading $zipName ...');
    final zipPath = '${Directory.systemTemp.path}${Platform.pathSeparator}$zipName';
    final zipFile = File(zipPath);
    final zReq = await client.getUrl(Uri.parse(zipUrl));
    zReq.headers.set('User-Agent', 'QuestLoad-Launcher');
    final zRes = await zReq.close();
    if (zRes.statusCode != 200) {
      stderr.writeln('Download failed: HTTP ${zRes.statusCode}');
      exit(1);
    }
    final sink = zipFile.openWrite();
    await zRes.pipe(sink);
    await sink.close();

    // Extract via PowerShell (avoids archive package). Works on Windows.
    stdout.writeln('Extracting to $installRoot ...');
    final extractTmp = '${Directory.systemTemp.path}${Platform.pathSeparator}ql_extract_${DateTime.now().millisecondsSinceEpoch}';
    String ps(String s) => "'${s.replaceAll("'", "''")}'";
    final script = '''
\$zip = ${ps(zipPath)}
\$tmp = ${ps(extractTmp)}
\$dest = ${ps(installRoot)}
if (Test-Path \$tmp) { Remove-Item -Recurse -Force \$tmp }
Expand-Archive -Path \$zip -DestinationPath \$tmp -Force
\$innerQlapp = Join-Path \$tmp 'qlapp'
\$innerQuest = Join-Path \$tmp 'questload'
\$src = if (Test-Path \$innerQlapp) { \$innerQlapp } elseif (Test-Path \$innerQuest) { \$innerQuest } else { \$tmp }
\$target = Join-Path \$dest 'qlapp'
if (!(Test-Path \$target)) { New-Item -ItemType Directory -Force \$target | Out-Null }
Copy-Item -Path (Join-Path \$src '*') -Destination \$target -Recurse -Force
Remove-Item -Recurse -Force \$tmp
Remove-Item -Force \$zip
''';
    final r = await Process.run('powershell', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      script,
    ]);
    if (r.exitCode != 0) {
      stderr.writeln('Extract failed: ${r.stderr} ${r.stdout}');
      exit(1);
    }
    stdout.writeln('Installed to ${installRoot}${Platform.pathSeparator}qlapp');
    if (await appFile.exists()) {
      await Process.start(qlappExe, [], mode: ProcessStartMode.detached);
    }
    exit(0);
  } catch (e) {
    stderr.writeln('Install failed: $e');
    exit(1);
  }
}
