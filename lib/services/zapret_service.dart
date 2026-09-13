import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

import '../core/app_localization.dart';

/// РЎРµСЂРІРёСЃ + ChangeNotifier-СЃРѕСЃС‚РѕСЏРЅРёРµ РґР»СЏ UI.
/// Р’СЃРµ РїРѕР»СЊР·РѕРІР°С‚РµР»СЊСЃРєРёРµ СЃС‚СЂРѕРєРё вЂ” С‡РµСЂРµР· Loc.t(...) / Loc.mode(...).
class ZapretService extends ChangeNotifier {
  ZapretService._();
  static final ZapretService instance = ZapretService._();

  /// Р РµРїРѕР·РёС‚РѕСЂРёР№, РІ РєРѕС‚РѕСЂРѕРј РїСѓР±Р»РёРєСѓСЋС‚СЃСЏ СЂРµР»РёР·С‹ Р­РўРћР“Рћ РїСЂРёР»РѕР¶РµРЅРёСЏ
  /// (zip СЃРѕ СЃР±РѕСЂРєРѕР№ Windows). РџРѕРјРµРЅСЏР№ РЅР° СЃРІРѕР№, РµСЃР»Рё СЂРµР»РёР·С‹ Р»РµР¶Р°С‚ РёРЅР°С‡Рµ.
  static const String appRepo = 'Ank01rd/z2-lite';   // Р±С‹Р»Рѕ 'Ank01rd/ZapretManager'

  /// РўРµРєСѓС‰Р°СЏ РІРµСЂСЃРёСЏ РїСЂРёР»РѕР¶РµРЅРёСЏ (СЃРёРЅС…СЂРѕРЅРёР·РёСЂСѓР№ СЃ pubspec.yaml).
  static const String currentAppVersion = '1.0.4';

  String _zapretDir = r'C:\zapret_programm';
  String get zapretDir => _zapretDir;
  set zapretDir(String p) {
    _zapretDir = p;
    notifyListeners();
  }

  // в”Ђв”Ђ UI-СЃРѕСЃС‚РѕСЏРЅРёРµ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  List<String> _configs = const [];
  bool _running = false;
  bool _busy = false;
  String _gameFilter = 'disabled'; // disabled | all | tcp | udp
  String _ipsetStatus = 'any'; // loaded | none | any

  List<String> get configs => _configs;
  bool get running => _running;
  bool get busy => _busy;
  String get gameFilter => _gameFilter;
  String get ipsetStatus => _ipsetStatus;

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();
  }

  Future<void> refresh() async {
    _setBusy(true);
    try {
      _configs = await scanConfigs();
      _running = await isRunning();
      _gameFilter = await _readGameFilter();
      _ipsetStatus = await _readIpsetStatus();
    } finally {
      _setBusy(false);
    }
  }

  /// РџСЂРёРЅСѓРґРёС‚РµР»СЊРЅР°СЏ СЃРёРЅС…СЂРѕРЅРёР·Р°С†РёСЏ UI-СЃРѕСЃС‚РѕСЏРЅРёСЏ СЃ РґРёСЃРєРѕРј.
  Future<void> syncStatus() async {
    _running = await isRunning();
    _gameFilter = await _readGameFilter();
    _ipsetStatus = await _readIpsetStatus();
    notifyListeners();
  }

  // в”Ђв”Ђ СЃРѕС…СЂР°РЅС‘РЅРЅС‹Р№ РїСѓС‚СЊ Рє РїР°РїРєРµ Zapret в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  Future<String?> getSavedPath() async {
    final file =
        File('${Platform.environment['APPDATA']}\\Z2Mini\\zapret_path.json');
    if (!await file.exists()) return null;
    try {
      return (jsonDecode(await file.readAsString()))['path'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> savePath(String path) async {
    final file =
        File('${Platform.environment['APPDATA']}\\Z2Mini\\zapret_path.json');
    file.parent.createSync(recursive: true);
    await file.writeAsString(jsonEncode({'path': path}));
  }

  // в”Ђв”Ђ РєРѕРЅС„РёРіРё: РІСЃРµ .bat РєСЂРѕРјРµ service.bat, СЃРѕСЂС‚РёСЂРѕРІРєР° РєР°Рє РІ РїСЂРѕРІРѕРґРЅРёРєРµ в”Ђв”Ђ
  Future<List<String>> scanConfigs() async {
    return scanConfigsIn(_zapretDir);
  }

  Future<List<String>> scanConfigsIn(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];
    final configs = <String>[];
    for (final e in dir.listSync()) {
      if (e is File) {
        final n = e.path.replaceAll('\\', '/').split('/').last.toLowerCase();
        if (n.endsWith('.bat') && n != 'service.bat') {
          configs.add(e.path.replaceAll('\\', '/').split('/').last);
        }
      }
    }
    configs.sort(_naturalCompare); // ALT2 СЂР°РЅСЊС€Рµ ALT10
    return configs;
  }

  /// В«РџСЂРѕРІРѕРґРЅРёРєРѕРІР°СЏВ» СЃРѕСЂС‚РёСЂРѕРІРєР°: С‡РёСЃР»Р° СЃСЂР°РІРЅРёРІР°СЋС‚СЃСЏ РєР°Рє С‡РёСЃР»Р°
  static int _naturalCompare(String a, String b) {
    final re = RegExp(r'(\d+|\D+)');
    final pa = re.allMatches(a).map((m) => m.group(0)!).toList();
    final pb = re.allMatches(b).map((m) => m.group(0)!).toList();
    for (var i = 0; i < pa.length && i < pb.length; i++) {
      final xa = pa[i], xb = pb[i];
      final numA = RegExp(r'^\d+$').hasMatch(xa);
      final numB = RegExp(r'^\d+$').hasMatch(xb);
      final c = (numA && numB)
          ? int.parse(xa).compareTo(int.parse(xb))
          : xa.toLowerCase().compareTo(xb.toLowerCase());
      if (c != 0) return c;
    }
    return pa.length.compareTo(pb.length);
  }

  // в”Ђв”Ђ СЃС‚Р°С‚СѓСЃ / Р·Р°РїСѓСЃРє / РѕСЃС‚Р°РЅРѕРІРєР° / РїРµСЂРµР·Р°РїСѓСЃРє в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  Future<bool> isRunning() async {
    try {
      final r = await Process.run(
          'tasklist', ['/FI', 'IMAGENAME eq winws.exe', '/NH'],
          runInShell: true);
      return r.stdout.toString().toLowerCase().contains('winws.exe');
    } catch (_) {
      return false;
    }
  }

  Future<String> start(String configName) async {
    if (_busy) return Loc.t('msgBusy');
    _setBusy(true);
    final msg = '${Loc.t('msgLaunch')}: $configName (UAC)';
    final path = '$_zapretDir\\$configName';
    await Process.run('powershell', [
      '-Command',
      'Start-Process -FilePath "cmd.exe" '
          '-ArgumentList \'/c ""$path""\' '
          '-WorkingDirectory "$_zapretDir" -Verb RunAs'
    ]);
    await Future.delayed(const Duration(milliseconds: 900));
    _running = await isRunning();
    _setBusy(false);
    return msg;
  }

  Future<String> stop() async {
    if (_busy) return Loc.t('msgBusy');
    _setBusy(true);
    await Process.run('powershell', [
      '-Command',
      'Start-Process -FilePath "taskkill" '
          '-ArgumentList "/F /IM winws.exe" -Verb RunAs -WindowStyle Hidden'
    ]);
    await Future.delayed(const Duration(milliseconds: 500));
    _running = await isRunning();
    _setBusy(false);
    return Loc.t('msgStop');
  }

  Future<String> restart(String configName) async {
    await stop();
    return start(configName);
  }

  // в”Ђв”Ђ Game Filter: utils/game_filter.enabled (all | tcp | udp) в”Ђв”Ђ
  Future<String> _readGameFilter() async {
    final f = File('$_zapretDir\\utils\\game_filter.enabled');
    if (!await f.exists()) return 'disabled';
    try {
      return (await f.readAsLines())
          .map((l) => l.trim().toLowerCase())
          .firstWhere((l) => l.isNotEmpty, orElse: () => 'disabled');
    } catch (_) {
      return 'disabled';
    }
  }

  Future<String> setGameFilterMode(String mode) async {
    final f = File('$_zapretDir\\utils\\game_filter.enabled');
    String? error;
    try {
      if (mode == 'disabled') {
        if (await f.exists()) await f.delete();
      } else {
        await f.parent.create(recursive: true);
        await f.writeAsString(mode);
      }
    } catch (e) {
      error = 'Game Filter: ${Loc.t('msgError')} $e';
    }
    await syncStatus();
    if (error != null) return error;
    return 'Game Filter: ${Loc.mode(mode)} В· ${Loc.t('msgApplies')}';
  }

  // в”Ђв”Ђ IPSet Filter: СЃРѕСЃС‚РѕСЏРЅРёСЏ СЃРїРёСЃРєР° lists/ipset-all.txt в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  Future<String> _readIpsetStatus() async {
    final f = File('$_zapretDir\\lists\\ipset-all.txt');
    if (!await f.exists()) return 'any';
    try {
      final lines = (await f.readAsLines())
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      if (lines.isEmpty) return 'any';
      if (lines.any((l) => l.contains('203.0.113.113/32'))) return 'none';
      return 'loaded';
    } catch (_) {
      return 'any';
    }
  }

  Future<String> setIpsetFilter(String target) async {
    final dir = _zapretDir;
    final list = File('$dir\\lists\\ipset-all.txt');
    final backup = File('$dir\\lists\\ipset-all.txt.backup');

    final current = await _readIpsetStatus();
    if (current == target) {
      await syncStatus();
      return 'IPSet: ${Loc.t('msgAlready')} ${Loc.mode(target)}';
    }

    String? error;
    try {
      switch (target) {
        case 'none':
          if (await list.exists()) {
            if (!await backup.exists()) {
              await list.rename(backup.path);
            } else {
              await list.delete();
            }
          }
          await list.parent.create(recursive: true);
          await list.writeAsString('203.0.113.113/32\r\n');

        case 'any':
          if (!await backup.exists() && await list.exists()) {
            final lines = (await list.readAsLines())
                .map((l) => l.trim())
                .where((l) => l.isNotEmpty)
                .toList();
            final isMarker =
                lines.length == 1 && lines.first.contains('203.0.113.113/32');
            if (lines.isNotEmpty && !isMarker) {
              await list.rename(backup.path);
            }
          }
          await list.parent.create(recursive: true);
          await list.writeAsString('');

        case 'loaded':
          if (await backup.exists()) {
            if (await list.exists()) await list.delete();
            await backup.rename(list.path);
          } else {
            var needDownload = true;
            if (await list.exists()) {
              final lines = (await list.readAsLines())
                  .map((l) => l.trim())
                  .where((l) => l.isNotEmpty)
                  .toList();
              final isMarker =
                  lines.length == 1 && lines.first.contains('203.0.113.113/32');
              needDownload = lines.isEmpty || isMarker;
            }
            if (needDownload) {
              final msg = await updateIpset(dir);
              if (!msg.contains(Loc.t('msgIpsetUpdated'))) error = msg;
            }
          }

        default:
          await syncStatus();
          return 'IPSet: ${Loc.t('msgUnknown')} ${Loc.mode(target)}';
      }
    } catch (e) {
      error = '${Loc.t('msgIpsetError')}: $e';
    }

    await syncStatus();
    if (error != null) return error;
    return 'IPSet: ${Loc.mode(_ipsetStatus)} В· ${Loc.t('msgApplies')}';
  }

  // в”Ђв”Ђ РїСЂРёРјРµРЅРµРЅРёРµ С„РёР»СЊС‚СЂРѕРІ (СЃРѕРІРјРµСЃС‚РёРјРѕСЃС‚СЊ СЃРѕ СЃС‚Р°СЂС‹Рј API) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  Future<void> applySettings({
    required String folder,
    required String gameFilter,
    required String ipsetFilter,
  }) async {
    await setGameFilterMode(gameFilter);
    if (ipsetFilter != _ipsetStatus) await setIpsetFilter(ipsetFilter);
  }

  // в”Ђв”Ђ Р°РІС‚РѕР·Р°РїСѓСЃРє С‡РµСЂРµР· schtasks в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  Future<bool> isAutostartInstalled() async {
    try {
      final r = await Process.run(
          'schtasks', ['/Query', '/TN', 'Z2-AutoStart', '/NH'],
          runInShell: true);
      return r.exitCode == 0 && r.stdout.toString().contains('Z2-AutoStart');
    } catch (_) {
      return false;
    }
  }

  Future<String> installService(String folder, {String? config}) async {
    final configs = await scanConfigsIn(folder);
    if (configs.isEmpty) return Loc.t('msgNoConfigs');

    String? cfg;
    if (config != null && config.isNotEmpty) {
      final lower = config.toLowerCase().trim();
      for (final c in configs) {
        if (c.toLowerCase().trim() == lower) {
          cfg = c;
          break;
        }
      }
    }
    if (cfg == null) {
      if (configs.any((c) => c.toLowerCase().contains('general (alt)'))) {
        cfg =
            configs.firstWhere((c) => c.toLowerCase().contains('general (alt)'));
      } else if (configs.any((c) => c.toLowerCase() == 'general.bat')) {
        cfg = configs.firstWhere((c) => c.toLowerCase() == 'general.bat');
      } else {
        cfg = configs.first;
      }
    }

    await Process.run('powershell', [
      '-Command',
      'Start-Process -FilePath "schtasks" '
          '-ArgumentList \'/Create /TN "Z2-AutoStart" '
          '/SC ONLOGON /RL HIGHEST /TR ""$folder\\$cfg"" /F\' '
          '-Verb RunAs -WindowStyle Hidden'
    ]);
    return '${Loc.t('msgAutostartSet')}: $cfg';
  }

  Future<String> removeService(String folder) async {
    await Process.run('powershell', [
      '-Command',
      'Start-Process -FilePath "schtasks" '
          '-ArgumentList \'/Delete /TN "Z2-AutoStart" /F\' '
          '-Verb RunAs -WindowStyle Hidden'
    ]);
    return Loc.t('msgAutostartRemoved');
  }

   /// РџРѕР»РЅРѕРµ СѓРґР°Р»РµРЅРёРµ СЃР»СѓР¶Р± zapret вЂ” Р°РЅР°Р»РѕРі "Remove Services" РёР· service.bat:
  /// net stop + sc delete zapret, taskkill winws, WinDivert, WinDivert14.
  /// Bat СѓРґР°Р»СЏРµС‚ СЃРµР±СЏ РЎРђРњ РїРѕСЃР»РµРґРЅРµР№ СЃС‚СЂРѕРєРѕР№, РїРѕСЌС‚РѕРјСѓ РЅРµ Р»РѕРјР°РµС‚СЃСЏ РЅР° СЃРµСЂРµРґРёРЅРµ.
  Future<String> removeZapretService() async {
    if (_busy) return Loc.t('msgBusy');
    _setBusy(true);
    try {
      final tmp =
          File('${Platform.environment['TEMP']}\\z2_remove_service.bat');
      tmp.writeAsStringSync('''
@echo off
rem в”Ђв”Ђ СЃР»СѓР¶Р±Р° zapret: РѕСЃС‚Р°РЅРѕРІРёС‚СЊ Рё СѓРґР°Р»РёС‚СЊ в”Ђв”Ђ
sc query zapret >nul 2>&1
if %errorlevel%==0 (
  net stop zapret >nul 2>&1
  sc delete zapret >nul 2>&1
)
rem в”Ђв”Ђ standalone winws (РµСЃР»Рё Р·Р°РїСѓСЃРєР°Р»СЃСЏ С‡РµСЂРµР· .bat) в”Ђв”Ђ
taskkill /IM winws.exe /F >nul 2>&1
rem в”Ђв”Ђ РґСЂР°Р№РІРµСЂС‹ WinDivert в”Ђв”Ђ
sc query WinDivert >nul 2>&1
if %errorlevel%==0 (
  net stop WinDivert >nul 2>&1
  sc delete WinDivert >nul 2>&1
)
net stop WinDivert14 >nul 2>&1
sc delete WinDivert14 >nul 2>&1
rem в”Ђв”Ђ РєРѕРЅС‚СЂРѕР»СЊРЅС‹Р№ kill: СЃР»СѓР¶Р±Р° РјРѕРіР»Р° РїРµСЂРµР·Р°РїСѓСЃС‚РёС‚СЊ winws в”Ђв”Ђ
timeout /t 2 /nobreak >nul
taskkill /IM winws.exe /F >nul 2>&1
rem в”Ђв”Ђ СЃР°РјРѕСѓРґР°Р»РµРЅРёРµ РџРћРЎР›Р• РІСЃРµС… РєРѕРјР°РЅРґ (cmd С‡РёС‚Р°РµС‚ bat РїРѕСЃС‚СЂРѕС‡РЅРѕ,
rem    РїРѕСЌС‚РѕРјСѓ СѓРґР°Р»СЏС‚СЊ РµРіРѕ РёР· Dart СЂР°РЅСЊС€Рµ РІСЂРµРјРµРЅРё РЅРµР»СЊР·СЏ) в”Ђв”Ђ
del /f /q "%~f0" >nul 2>nul
''');
      await Process.run('powershell', [
        '-Command',
        'Start-Process -FilePath "${tmp.path}" -Verb RunAs -WindowStyle Hidden'
      ]);
      // Р¶РґС‘Рј Р·Р°РІРµСЂС€РµРЅРёСЏ СЃРєСЂРёРїС‚Р° (net stop + timeout 2 + taskkill в‰€ 4-5 c)
      await Future.delayed(const Duration(seconds: 5));
      await syncStatus();
      return Loc.t('msgServiceRemoved');
    } catch (e) {
      return '${Loc.t('msgError')}: $e';
    } finally {
      _setBusy(false);
    }
  }

  // в”Ђв”Ђ РѕР±РЅРѕРІР»РµРЅРёРµ IPSet в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  Future<String> updateIpset(String folder) async {
    String result;
    try {
      await Directory('$folder\\lists').create(recursive: true);
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(Uri.parse(
          'https://raw.githubusercontent.com/Flowseal/zapret-discord-youtube/refs/heads/main/.service/ipset-service.txt'));
      req.headers.set('User-Agent', 'Z2-Mini');
      final resp = await req.close();
      if (resp.statusCode == 200) {
        final sink = File('$folder\\lists\\ipset-all.txt').openWrite();
        await resp.pipe(sink);
        await sink.close();
        client.close();
        final written = await File('$folder\\lists\\ipset-all.txt').length();
        if (written == 0) {
          result = '${Loc.t('msgIpsetError')}: ${Loc.t('msgEmpty')}';
        } else {
          result = Loc.t('msgIpsetUpdated');
        }
      } else {
        client.close();
        result = '${Loc.t('msgIpsetHttp')} ${resp.statusCode}';
      }
    } catch (e) {
      result = '${Loc.t('msgIpsetError')}: $e';
    }
    await syncStatus();
    return result;
  }

  // в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ
  //  РЈРЎРўРђРќРћР’РљРђ / РћР‘РќРћР’Р›Р•РќРР• ZAPRET (СЂР°Р±РѕС‚Р°РµС‚ Сѓ Р»СЋР±РѕРіРѕ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ)
  // в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ

  /// Р›РѕРєР°Р»СЊРЅР°СЏ РІРµСЂСЃРёСЏ zapret РёР· version.txt (РµСЃР»Рё РµСЃС‚СЊ).
  Future<String?> zapretLocalVersion() async {
    final f = File('$_zapretDir\\version.txt');
    if (!await f.exists()) return null;
    try {
      return (await f.readAsString()).trim();
    } catch (_) {
      return null;
    }
  }

  /// Р•СЃС‚СЊ Р»Рё Р±РѕР»РµРµ РЅРѕРІР°СЏ РІРµСЂСЃРёСЏ zapret РЅР° GitHub.
  Future<bool> isZapretUpdateAvailable() async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(Uri.parse(
          'https://api.github.com/repos/Flowseal/zapret-discord-youtube/releases/latest'));
      req.headers.set('User-Agent', 'Z2-Mini');
      final resp = await req.close();
      if (resp.statusCode != 200) {
        client.close();
        return false;
      }
      final data = jsonDecode(await resp.transform(utf8.decoder).join());
      client.close();
      final latest = '${data['tag_name']}'.replaceFirst(RegExp('^v'), '');
      final local = await zapretLocalVersion();
      if (local == null) return true; // РІРµСЂСЃРёРё РЅРµС‚ вЂ” СЃС‡РёС‚Р°РµРј, С‡С‚Рѕ РѕР±РЅРѕРІР»РµРЅРёРµ РЅСѓР¶РЅРѕ
      return _isNewer(latest, local.replaceFirst(RegExp('^v'), ''));
    } catch (_) {
      return false;
    }
  }

  /// РЎРєР°С‡РёРІР°РµС‚ РїРѕСЃР»РµРґРЅРёР№ СЂРµР»РёР· Zapret Рё СѓСЃС‚Р°РЅР°РІР»РёРІР°РµС‚ РІ [folder]:
  ///  1) РєР°С‡Р°РµС‚ zip СЂРµР»РёР·Р°;
  ///  2) СЂР°СЃРїР°РєРѕРІС‹РІР°РµС‚ РІРѕ РІСЂРµРјРµРЅРЅСѓСЋ РїР°РїРєСѓ (С‡РёСЃС‚С‹Р№ Dart в†’ PowerShell в†’ tar);
  ///  3) РµСЃР»Рё РІРЅСѓС‚СЂРё РѕРґРЅР° РєРѕСЂРЅРµРІР°СЏ РїР°РїРєР° вЂ” СЃР»РёРІР°РµС‚ РµС‘ СЃРѕРґРµСЂР¶РёРјРѕРµ СЃ [folder];
  ///  4) РґРѕРїРѕР»РЅРёС‚РµР»СЊРЅРѕ РїРѕРґРЅРёРјР°РµС‚ Р»СЋР±С‹Рµ РІР»РѕР¶РµРЅРЅС‹Рµ zapret-discord-youtube-*;
  ///  5) РїСЂРѕРІРµСЂСЏРµС‚, С‡С‚Рѕ РїРѕСЏРІРёР»РёСЃСЊ .bat-РєРѕРЅС„РёРіРё, Рё РїРёС€РµС‚ version.txt.
  Future<String> downloadZapret(String folder,
      {void Function(double? p, String stage)? onProgress}) async {
    if (_busy) return Loc.t('msgBusy');
    _setBusy(true);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    final tmpDir = Directory('$folder\\__zapret_tmp');
    try {
      onProgress?.call(null, Loc.t('msgSearch'));
      final req = await client.getUrl(Uri.parse(
          'https://api.github.com/repos/Flowseal/zapret-discord-youtube/releases/latest'));
      req.headers.set('User-Agent', 'Z2-Mini');
      final resp = await req.close();
      if (resp.statusCode != 200) {
        return '${Loc.t('msgHttp')}: ${resp.statusCode}';
      }
      final data = jsonDecode(await resp.transform(utf8.decoder).join());
      final assets = (data['assets'] as List).cast<Map<String, dynamic>>();
      String? url;
      for (final a in assets) {
        if ((a['name'] as String).toLowerCase().endsWith('.zip')) {
          url = a['browser_download_url'] as String;
          break;
        }
      }
      if (url == null) return Loc.t('msgNoZip');
      final version = '${data['tag_name']}';

      await Directory(folder).create(recursive: true);
      final zipPath = '$folder\\zapret_download.zip';

      // в”Ђв”Ђ СЃРєР°С‡РёРІР°РЅРёРµ СЃ РїСЂРѕРіСЂРµСЃСЃРѕРј в”Ђв”Ђ
      final dl = await client.getUrl(Uri.parse(url));
      dl.headers.set('User-Agent', 'Z2-Mini');
      final dlResp = await dl.close();
      final total = dlResp.contentLength;
      final sink = File(zipPath).openWrite();
      var received = 0;
      var lastPct = -1;
      await for (final chunk in dlResp) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          final pct = received * 100 ~/ total;
          if (pct != lastPct) {
            lastPct = pct;
            onProgress?.call(
                pct / 100, '${Loc.t('msgDownloading')} $version В· $pct%');
            await Future.delayed(const Duration(milliseconds: 50));
          }
        } else {
          onProgress?.call(null,
              '${Loc.t('msgDownloading')} $versionвЂ¦ ${received ~/ 1048576} MB');
        }
      }
      await sink.close();

      // в”Ђв”Ђ СЂР°СЃРїР°РєРѕРІРєР° РІРѕ РІСЂРµРјРµРЅРЅСѓСЋ РїР°РїРєСѓ: 3 СЃРїРѕСЃРѕР±Р° РїРѕРґСЂСЏРґ в”Ђв”Ђ
      onProgress?.call(null, Loc.t('msgExtracting'));
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
      tmpDir.createSync(recursive: true);

      var extracted = false;
      try {
        _unzipPureDart(zipPath, tmpDir.path); // 1) С‡РёСЃС‚С‹Р№ Dart вЂ” СЂР°Р±РѕС‚Р°РµС‚ РІСЃРµРіРґР°
        extracted = true;
      } catch (_) {}
      if (!extracted) {
        final ps = await Process.run('powershell', [
          '-NoProfile',
          '-Command',
          'Expand-Archive -LiteralPath "$zipPath" -DestinationPath "${tmpDir.path}" -Force'
        ]); // 2) PowerShell
        extracted = ps.exitCode == 0;
      }
      if (!extracted) {
        final tar =
            await Process.run('tar', ['-xf', zipPath, '-C', tmpDir.path]);
        extracted = tar.exitCode == 0; // 3) tar (РµСЃС‚СЊ РІ Windows 10+)
      }
      if (!extracted) return Loc.t('msgUnpack');

      // в”Ђв”Ђ РїРµСЂРµРЅРѕСЃ РІ С†РµР»РµРІСѓСЋ РїР°РїРєСѓ (flatten РѕРґРёРЅРѕС‡РЅРѕРіРѕ РєРѕСЂРЅСЏ) в”Ђв”Ђ
      onProgress?.call(null, Loc.t('msgInstalling'));
      final entries = tmpDir.listSync();
      final singleRoot =
          entries.length == 1 && entries.single is Directory
              ? entries.single as Directory
              : tmpDir;
      await _moveInto(singleRoot, Directory(folder));
      await _flatten(folder); // РїРѕРґРЅРёРјРµРј zapret-discord-youtube-* РµСЃР»Рё РѕСЃС‚Р°Р»РёСЃСЊ

      try {
        tmpDir.deleteSync(recursive: true);
      } catch (_) {}
      try {
        await File(zipPath).delete();
      } catch (_) {}

      // в”Ђв”Ђ РїСЂРѕРІРµСЂРєР° С†РµР»РѕСЃС‚РЅРѕСЃС‚Рё: РєРѕРЅС„РёРіРё РёР»Рё winws.exe РЅР° РјРµСЃС‚Рµ в”Ђв”Ђ
      final ok = (await scanConfigsIn(folder)).isNotEmpty ||
          await File('$folder\\bin\\winws.exe').exists();
      if (!ok) return Loc.t('msgUnpack');

      try {
        await File('$folder\\version.txt').writeAsString(version);
      } catch (_) {}
      await refresh();
      return 'Zapret $version ${Loc.t('msgInstalled')}';
    } catch (e) {
      return '${Loc.t('msgDownloadError')}: $e';
    } finally {
      client.close();
      _setBusy(false);
    }
  }

  /// Р Р°СЃРїР°РєРѕРІРєР° zip СЃСЂРµРґСЃС‚РІР°РјРё Dart (РїР°РєРµС‚ archive) вЂ” РЅРµ Р·Р°РІРёСЃРёС‚
  /// РѕС‚ PowerShell/tar/РїСЂР°РІ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ. РЎ Р·Р°С‰РёС‚РѕР№ РѕС‚ zip-slip.
  void _unzipPureDart(String zipPath, String destDir) {
    final bytes = File(zipPath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final name = file.name.replaceAll('/', '\\');
      if (name.contains('..')) continue; // zip-slip Р·Р°С‰РёС‚Р°
      final outPath = '$destDir\\$name';
      if (file.isFile) {
        File(outPath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(file.content as List<int>);
      } else {
        Directory(outPath).createSync(recursive: true);
      }
    }
  }

  /// Р•СЃР»Рё РїРѕСЃР»Рµ СЂР°СЃРїР°РєРѕРІРєРё РѕСЃС‚Р°Р»РёСЃСЊ РІР»РѕР¶РµРЅРЅС‹Рµ РїР°РїРєРё СЂРµР»РёР·Р°
  /// (zapret-discord-youtube-x.y.z) вЂ” СЃР»РёРІР°РµРј РёС… СЃРѕРґРµСЂР¶РёРјРѕРµ СЃ РєРѕСЂРЅРµРј.
  Future<void> _flatten(String dir) async {
    for (var pass = 0; pass < 2; pass++) {
      final root = Directory(dir);
      if (!await root.exists()) return;
      final nested = root
          .listSync()
          .whereType<Directory>()
          .where((d) => d.path
              .replaceAll('\\', '/')
              .split('/')
              .last
              .toLowerCase()
              .startsWith('zapret-discord-youtube'))
          .toList();
      if (nested.isEmpty) return;
      for (final d in nested) {
        await _moveInto(d, root);
        try {
          await d.delete(recursive: true);
        } catch (_) {}
      }
    }
  }

  /// Р РµРєСѓСЂСЃРёРІРЅРѕ РїРµСЂРµРЅРѕСЃРёС‚ СЃРѕРґРµСЂР¶РёРјРѕРµ src РІ dst, СЃР»РёРІР°СЏ РїР°РїРєРё
  /// Рё Р·Р°РјРµРЅСЏСЏ С„Р°Р№Р»С‹.
  Future<void> _moveInto(Directory src, Directory dst) async {
    for (final e in src.listSync()) {
      final name = e.path.replaceAll('\\', '/').split('/').last;
      final dest = '${dst.path}\\$name';
      try {
        if (e is Directory) {
          if (await Directory(dest).exists()) {
            await _moveInto(e, Directory(dest));
          } else {
            await e.rename(dest);
          }
        } else {
          if (await File(dest).exists()) await File(dest).delete();
          await e.rename(dest);
        }
      } catch (_) {}
    }
  }

  // в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ
  //  OTA-РћР‘РќРћР’Р›Р•РќРРЇ РЎРђРњРћР“Рћ РџР РР›РћР–Р•РќРРЇ (Z2 Mini Lite)
  // в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ

  /// РЎСЂР°РІРЅРµРЅРёРµ РІРµСЂСЃРёР№ РІРёРґР° 1.5.0 / v1.6.2.
  static bool _isNewer(String latest, String current) {
    List<int> parse(String s) => s
        .split('.')
        .map((e) => int.tryParse(e.replaceAll(RegExp(r'\D'), '')) ?? 0)
        .toList();
    final a = parse(latest);
    final b = parse(current);
    for (var i = 0; i < 3; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  /// Р•СЃС‚СЊ Р»Рё РЅРѕРІР°СЏ РІРµСЂСЃРёСЏ РїСЂРёР»РѕР¶РµРЅРёСЏ (Р±РµР· СѓСЃС‚Р°РЅРѕРІРєРё).
  Future<String?> checkAppUpdateTag() async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(
          Uri.parse('https://api.github.com/repos/$appRepo/releases/latest'));
      req.headers.set('User-Agent', 'Z2-Mini');
      final resp = await req.close();
      if (resp.statusCode != 200) {
        client.close();
        return null;
      }
      final data = jsonDecode(await resp.transform(utf8.decoder).join());
      client.close();
      return '${data['tag_name']}'.replaceFirst(RegExp('^v'), '');
    } catch (_) {
      return null;
    }
  }

  Future<String> checkAppUpdate() async {
    final tag = await checkAppUpdateTag();
    if (tag == null) return Loc.t('msgError');
    return '${Loc.t('msgLatestZ2')}: $tag';
  }

  /// РџСЂРѕРІРµСЂРєР° РѕР±РЅРѕРІР»РµРЅРёР№ СЃР°РјРѕРіРѕ Zapret (Flowseal).
  Future<String> checkZapretUpdate() async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(Uri.parse(
          'https://api.github.com/repos/Flowseal/zapret-discord-youtube/releases/latest'));
      req.headers.set('User-Agent', 'Z2-Mini');
      final resp = await req.close();
      if (resp.statusCode != 200) {
        client.close();
        return '${Loc.t('msgHttp')}: ${resp.statusCode}';
      }
      final data = jsonDecode(await resp.transform(utf8.decoder).join());
      client.close();
      return 'Flowseal: ${data['tag_name']}';
    } catch (e) {
      return '${Loc.t('msgError')}: $e';
    }
  }

  /// OTA-РѕР±РЅРѕРІР»РµРЅРёРµ РїСЂРёР»РѕР¶РµРЅРёСЏ:
  ///  1) СЃРІРµСЂСЏРµС‚ РІРµСЂСЃРёСЋ СЃ РїРѕСЃР»РµРґРЅРёРј СЂРµР»РёР·РѕРј [appRepo];
  ///  2) РєР°С‡Р°РµС‚ zip-СЃР±РѕСЂРєСѓ Windows РІ %TEMP%\z2mini_update;
  ///  3) СЂР°СЃРїР°РєРѕРІС‹РІР°РµС‚ (Dart в†’ PowerShell в†’ tar);
  ///  4) СЃРѕР·РґР°С‘С‚ update.bat, РєРѕС‚РѕСЂС‹Р№ РґРѕР¶РёРґР°РµС‚СЃСЏ РІС‹С…РѕРґР° РїСЂРѕРіСЂР°РјРјС‹,
  ///     Р·Р°РјРµРЅСЏРµС‚ С„Р°Р№Р»С‹ РІ РїР°РїРєРµ exe Рё РїРµСЂРµР·Р°РїСѓСЃРєР°РµС‚ РїСЂРёР»РѕР¶РµРЅРёРµ;
  ///  5) Р·Р°РїСѓСЃРєР°РµС‚ bat Рё Р·Р°РІРµСЂС€Р°РµС‚ С‚РµРєСѓС‰РёР№ РїСЂРѕС†РµСЃСЃ.
  Future<String> installAppUpdate(
      {void Function(double? p, String stage)? onProgress}) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      onProgress?.call(null, Loc.t('msgSearch'));
      final tag = await checkAppUpdateTag();
      if (tag == null) return Loc.t('msgError');
      if (!_isNewer(tag, currentAppVersion)) return Loc.t('otaLatest');

      final req = await client.getUrl(
          Uri.parse('https://api.github.com/repos/$appRepo/releases/latest'));
      req.headers.set('User-Agent', 'Z2-Mini');
      final resp = await req.close();
      if (resp.statusCode != 200) {
        return '${Loc.t('msgHttp')}: ${resp.statusCode}';
      }
      final data = jsonDecode(await resp.transform(utf8.decoder).join());
      final assets = (data['assets'] as List).cast<Map<String, dynamic>>();
      String? url;
      for (final a in assets) {
        final n = (a['name'] as String).toLowerCase();
        if (n.endsWith('.zip') &&
            (n.contains('windows') || n.contains('win64') || n.contains('z2'))) {
          url = a['browser_download_url'] as String;
          break;
        }
      }
      if (url == null) {
        for (final a in assets) {
          if ((a['name'] as String).toLowerCase().endsWith('.zip')) {
            url = a['browser_download_url'] as String;
            break;
          }
        }
      }
      if (url == null) return Loc.t('msgNoZip');

      final tmp = Directory('${Platform.environment['TEMP']}\\z2mini_update');
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
      tmp.createSync(recursive: true);
      final zipPath = '${tmp.path}\\update.zip';

      // в”Ђв”Ђ СЃРєР°С‡РёРІР°РЅРёРµ в”Ђв”Ђ
      final dl = await client.getUrl(Uri.parse(url));
      dl.headers.set('User-Agent', 'Z2-Mini');
      final dlResp = await dl.close();
      final total = dlResp.contentLength;
      final sink = File(zipPath).openWrite();
      var received = 0;
      var lastPct = -1;
      await for (final chunk in dlResp) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          final pct = received * 100 ~/ total;
          if (pct != lastPct) {
            lastPct = pct;
            onProgress?.call(
                pct / 100, '${Loc.t('msgDownloading')} $tag В· $pct%');
          }
        } else {
          onProgress?.call(null, '${Loc.t('msgDownloading')} $tagвЂ¦');
        }
      }
      await sink.close();

      // в”Ђв”Ђ СЂР°СЃРїР°РєРѕРІРєР° в”Ђв”Ђ
      onProgress?.call(null, Loc.t('msgExtracting'));
      final newDir = Directory('${tmp.path}\\new')..createSync(recursive: true);
      var extracted = false;
      try {
        _unzipPureDart(zipPath, newDir.path);
        extracted = true;
      } catch (_) {}
      if (!extracted) {
        final ps = await Process.run('powershell', [
          '-NoProfile',
          '-Command',
          'Expand-Archive -LiteralPath "$zipPath" -DestinationPath "${newDir.path}" -Force'
        ]);
        extracted = ps.exitCode == 0;
      }
      if (!extracted) {
        final tar = await Process.run('tar', ['-xf', zipPath, '-C', newDir.path]);
        extracted = tar.exitCode == 0;
      }
      if (!extracted) return Loc.t('msgUnpack');

      final entries = newDir.listSync();
      final src = entries.length == 1 && entries.single is Directory
          ? (entries.single as Directory).path
          : newDir.path;

      // в”Ђв”Ђ bat-Р°РїРґРµР№С‚РµСЂ: Р¶РґС‘С‚ РІС‹С…РѕРґР° РїСЂРѕРіСЂР°РјРјС‹ в†’ РјРµРЅСЏРµС‚ С„Р°Р№Р»С‹ в†’ СЃС‚Р°СЂС‚ в”Ђв”Ђ
      final exe = File(Platform.resolvedExecutable);
      final appDir = exe.parent.path;
      final exeName = exe.uri.pathSegments.last;
      final bat = File('${tmp.path}\\update.bat');
      // CRLF-РїРµСЂРµРЅРѕСЃС‹ (cmd.exe С‚СЂРµР±СѓРµС‚ РёРјРµРЅРЅРѕ РёС…), Р‘Р•Р— СЃР°РјРѕСѓРґР°Р»РµРЅРёСЏ
      // (СѓРґР°Р»РµРЅРёРµ РІС‹РїРѕР»РЅСЏРµРјРѕРіРѕ bat СЂРѕРЅСЏРµС‚ cmd РІ Р·Р°РІРёСЃР°РЅРёРµ),
      // Р»РёРјРёС‚ 30 РїРѕРїС‹С‚РѕРє (РЅРµ РІРёСЃРёРј РІРµС‡РЅРѕ), РѕРєРЅРѕ СЃРєСЂС‹С‚РѕРµ.
      final batLines = [
        '@echo off',
        'setlocal',
        'set "APP_DIR=$appDir"',
        'set "SRC=$src"',
        'set "EXE=$exeName"',
        'set /a tries=0',
        ':wait',
        'tasklist /FI "IMAGENAME eq %EXE%" 2>nul | find /I "%EXE%" >nul',
        'if errorlevel 1 goto copy',
        'timeout /t 1 /nobreak >nul',
        'set /a tries+=1',
        'if %tries% GEQ 30 goto copy',
        'goto wait',
        ':copy',
        'xcopy /E /Y /I /Q "%SRC%\\*" "%APP_DIR%\\" >nul',
        'start "" "%APP_DIR%\\%EXE%"',
        'endlocal',
        'exit /b 0',
      ];
      bat.writeAsStringSync(batLines.join('\r\n') + '\r\n');

            onProgress?.call(null, Loc.t('otaRestart'));
      await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        'Start-Process -FilePath "${bat.path}" -WindowStyle Hidden'
      ]);
      await Future.delayed(const Duration(milliseconds: 400));
      exit(0); // Р°РїРґРµР№С‚РµСЂ РїРѕРґС…РІР°С‚РёС‚ РїРѕСЃР»Рµ РІС‹С…РѕРґР°
    } catch (e) {
      return '${Loc.t('msgError')}: $e';
    } finally {
      client.close();
    }
  }
}
