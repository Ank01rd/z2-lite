import 'dart:convert';
import 'dart:io';

class WindowsAutostart {
  static const _key = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
  static const _name = 'Z2 Lite';
  static const _taskName = 'Z2-AutoStart';

  static String get executable => Platform.resolvedExecutable;

  // ── автозапуск самого приложения (реестр Run) ──────────────
  static Future<bool> isEnabled() async {
    try {
      final r = await Process.run(
        'reg.exe',
        ['query', _key, '/v', _name],
        runInShell: false,
      );
      if (r.exitCode != 0) return false;
      return r.stdout
          .toString()
          .toLowerCase()
          .contains(executable.toLowerCase());
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
        ['add', _key, '/v', _name, '/t', 'REG_SZ', '/d', executable, '/f'],
        runInShell: false,
      );
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  // ── автозапуск zapret (задача планировщика на вход в систему) ──
  static String? _lastError;
  /// Человекочитаемая причина последнего сбоя — показываем в тосте.
  static String? get lastError => _lastError;

  static String get _tempDir =>
      Platform.environment['TEMP'] ?? Directory.systemTemp.path;
  static String get _taskXmlPath =>
      '${Platform.environment['APPDATA'] ?? _tempDir}\\Z2MiniLite\\zapret_autostart.xml';
  static String get _logPath => '$_tempDir\\z2_schtasks_log.txt';
  static String get _batPath => '$_tempDir\\z2_schtasks_run.bat';

  static String _xml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  /// DOMAIN\USER — явный UserId в Principal.
  static String? _userId() {
    final user = Platform.environment['USERNAME'];
    final domain = Platform.environment['USERDOMAIN'];
    if (user == null || user.isEmpty) return null;
    if (domain == null || domain.isEmpty) return user;
    return '$domain\\$user';
  }

  /// Лог bat-обёртки. Bat переключает консоль в UTF-8 (chcp 65001),
  /// поэтому читаем utf8; latin1 — страховка от падения декодера.
  static String _readLog() {
    try {
      final bytes = File(_logPath).readAsBytesSync();
      String t;
      try {
        t = utf8.decode(bytes);
      } catch (_) {
        t = latin1.decode(bytes);
      }
      t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
      return t.length > 220 ? '${t.substring(0, 220)}…' : t;
    } catch (_) {
      return '';
    }
  }

  /// UTF-16 LE с BOM FF FE — единственный формат, который schtasks
  /// принимает без ошибок «не удалось переключить кодировку».
  static Future<void> _writeXmlUtf16(File file, String xml) async {
    final bytes = <int>[0xFF, 0xFE];
    for (final u in xml.codeUnits) {
      bytes.add(u & 0xFF);
      bytes.add((u >> 8) & 0xFF);
    }
    await file.writeAsBytes(bytes, flush: true);
  }

  static Future<bool> installZapret({
    required String folder,
    required String config,
  }) async {
    _lastError = null;
    try {
      final xmlFile = File(_taskXmlPath);
      await xmlFile.parent.create(recursive: true);
      final userId = _userId();
      final xml = '''<?xml version="1.0" encoding="UTF-16"?>
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
${userId == null ? '' : '      <UserId>${_xml(userId)}</UserId>\n'}      <LogonType>InteractiveToken</LogonType>
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
      await _writeXmlUtf16(xmlFile, xml);
    } catch (e) {
      _lastError = 'XML: $e';
      return false;
    }

    final code = await _runElevatedSchtasks(
        'schtasks /Create /TN "$_taskName" /XML "$_taskXmlPath" /F');
    if (code == null) return false; // причина уже в _lastError (UAC/сбой)
    if (code != 0) {
      final log = _readLog();
      _lastError =
          log.isEmpty ? 'schtasks /Create код $code' : 'schtasks: $log';
      return false;
    }
    final ok = await isZapretEnabled();
    if (!ok) _lastError = 'задача не найдена после создания';
    return ok;
  }

  static Future<bool> removeZapret() async {
    _lastError = null;
    final code =
        await _runElevatedSchtasks('schtasks /Delete /TN "$_taskName" /F');
    try {
      await File(_taskXmlPath).delete();
    } catch (_) {}
    if (code == null) return false;
    final still = await isZapretEnabled();
    return code == 0 || !still;
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

  /// Выполняет schtasks elevated ЧЕРЕЗ временный bat: bat сам пишет вывод
  /// в лог-файл (с RunAs прямой редирект невозможен) и переключает консоль
  /// в UTF-8, чтобы лог читался без кракозябр.
  /// null = не стартовало (UAC отменён / сбой) — причина в _lastError.
  static Future<int?> _runElevatedSchtasks(String schtasksCmd) async {
    try {
      File(_logPath).deleteSync();
    } catch (_) {}
    try {
      final bat = File(_batPath);
      bat.writeAsStringSync(
        '@echo off\r\n'
        'chcp 65001 >nul\r\n'
        '$schtasksCmd > "$_logPath" 2>&1\r\n'
        'exit /b %errorlevel%\r\n',
      );
      final ps = "\$p = Start-Process -FilePath '${bat.path}' "
          "-Verb RunAs -WindowStyle Hidden -Wait -PassThru; exit \$p.ExitCode;";
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
      // 0/1/2 — легитимные коды schtasks; остальное = сбой самого запуска
      if (r.exitCode != 0 && r.exitCode != 1 && r.exitCode != 2) {
        final err = r.stderr.toString();
        _lastError = err.toLowerCase().contains('canceled')
            ? 'UAC-запрос отменён'
            : 'не удалось запустить schtasks elevated';
        return null;
      }
      return r.exitCode;
    } catch (e) {
      _lastError = 'powershell: $e';
      return null;
    }
  }
}