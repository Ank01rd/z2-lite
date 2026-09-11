import 'dart:convert';
import 'dart:io';

class WindowsAutostart {
  static const _key = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
  static const _name = 'Z2 Lite';
  static const _taskName = 'Z2-AutoStart';

  static String get executable => Platform.resolvedExecutable;

  static Future<bool> isEnabled() async {
    try {
      final r = await Process.run(
        'reg.exe',
        ['query', _key, '/v', _name],
        runInShell: false,
      );
      if (r.exitCode != 0) return false;
      return r.stdout.toString().toLowerCase().contains(executable.toLowerCase());
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setEnabled(bool enabled) async {
    try {
      if (!enabled) {
        final r = await Process.run(
          'reg.exe',
          ['delete', _key, '/v', _name, '/f'],
          runInShell: false,
        );
        return r.exitCode == 0 || r.exitCode == 1;
      }

      final r = await Process.run(
        'reg.exe',
        [
          'add', _key,
          '/v', _name,
          '/t', 'REG_SZ',
          '/d', executable,
          '/f',
        ],
        runInShell: false,
      );
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static String get _taskXmlPath {
    final appData = Platform.environment['APPDATA'] ?? Directory.systemTemp.path;
    return '$appData\\Z2MiniLite\\zapret_autostart.xml';
  }

  static String _xml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  static Future<bool> installZapret({
    required String folder,
    required String config,
  }) async {
    try {
      final xmlFile = File(_taskXmlPath);
      await xmlFile.parent.create(recursive: true);

      // Use Task Scheduler XML instead of constructing a heavily quoted /TR
      // command. This keeps the working directory and .bat argument intact.
      final xml = '''<?xml version="1.0" encoding="UTF-8"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>Z2 Lite - automatic Zapret start</Description>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Enabled>true</Enabled>
    <Hidden>true</Hidden>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>cmd.exe</Command>
      <Arguments>/c call &quot;${_xml(config)}&quot;</Arguments>
      <WorkingDirectory>${_xml(folder)}</WorkingDirectory>
    </Exec>
  </Actions>
</Task>''';

      await xmlFile.writeAsString(xml, encoding: utf8);

      final result = await _runElevatedSchtasks([
        '/Create',
        '/TN', _taskName,
        '/XML', xmlFile.path,
        '/F',
      ]);

      if (result != 0) return false;
      return await isZapretEnabled();
    } catch (_) {
      return false;
    }
  }

  static Future<int> _runElevatedSchtasks(List<String> args) async {
    // PowerShell's ArgumentList array avoids manual escaping of Windows paths.
    final quoted = args.map((a) => "'${a.replaceAll("'", "''")}'").join(',');
    final ps = "\$p = Start-Process -FilePath 'schtasks.exe' -ArgumentList @($quoted) -Verb RunAs -WindowStyle Hidden -Wait -PassThru; exit \$p.ExitCode;";
    final r = await Process.run(
      'powershell.exe',
      [
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy', 'Bypass',
        '-Command', ps,
      ],
      runInShell: false,
    );
    return r.exitCode;
  }

  static Future<bool> isZapretEnabled() async {
    try {
      final r = await Process.run(
        'schtasks.exe',
        ['/Query', '/TN', _taskName],
        runInShell: false,
      );
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> removeZapret() async {
    try {
      final exitCode = await _runElevatedSchtasks([
        '/Delete',
        '/TN', _taskName,
        '/F',
      ]);
      try {
        await File(_taskXmlPath).delete();
      } catch (_) {}
      return exitCode == 0 || !(await isZapretEnabled());
    } catch (_) {
      return false;
    }
  }
}
