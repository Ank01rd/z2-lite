import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localization.dart';

class LiteSettings extends ChangeNotifier {
  LiteSettings._();

  static const _kDark = 'dark_theme';
  static const _kWin = 'launch_with_windows';
  static const _kAuto = 'zapret_autostart';
  static const _kCfg = 'selected_config';
  static const _kLang = 'language';

  bool _darkTheme = false;
  bool _launchWithWindows = false;
  bool _zapretAutostart = false;
  String _selectedConfig = '';
  String _language = 'ru';

  bool get darkTheme => _darkTheme;
  bool get launchWithWindows => _launchWithWindows;
  bool get zapretAutostart => _zapretAutostart;
  String get selectedConfig => _selectedConfig;
  String get language => _language;

  static Future<LiteSettings> load() async {
    final s = LiteSettings._();
    final p = await SharedPreferences.getInstance();
    // Первый запуск (ключа темы ещё нет): берём тему из Windows
    if (!p.getKeys().contains(_kDark)) {
      s._darkTheme = await _detectWindowsDark();
    } else {
      s._darkTheme = p.getBool(_kDark) ?? false;
    }
    s._launchWithWindows = p.getBool(_kWin) ?? false;
    s._zapretAutostart = p.getBool(_kAuto) ?? false;
    s._selectedConfig = p.getString(_kCfg) ?? '';
    s._language = p.getString(_kLang) ?? 'ru';
    Loc.lang = s._language;
    return s;
  }

  /// Читает тему приложений Windows: AppsUseLightTheme = 0 => тёмная.
  static Future<bool> _detectWindowsDark() async {
    try {
      final r = await Process.run(
        'reg.exe',
        [
          'query',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize',
          '/v',
          'AppsUseLightTheme',
        ],
        runInShell: false,
      );
      if (r.exitCode != 0) return false;
      final m = RegExp(r'AppsUseLightTheme\s+REG_DWORD\s+0x([0-9a-fA-F]+)')
          .firstMatch(r.stdout.toString());
      if (m == null) return false;
      return int.parse(m.group(1)!, radix: 16) == 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> setDarkTheme(bool v) => _update(() => _darkTheme = v);
  Future<void> setLaunchWithWindows(bool v) =>
      _update(() => _launchWithWindows = v);
  Future<void> setZapretAutostart(bool v) =>
      _update(() => _zapretAutostart = v);
  Future<void> setSelectedConfig(String v) =>
      _update(() => _selectedConfig = v);
  Future<void> setLanguage(String v) => _update(() {
        _language = v;
        Loc.lang = v; // сервис и тосты сразу говорят на новом языке
      });

  Future<void> _update(void Function() change) async {
    change();
    notifyListeners();
    await save();
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDark, _darkTheme);
    await p.setBool(_kWin, _launchWithWindows);
    await p.setBool(_kAuto, _zapretAutostart);
    await p.setString(_kCfg, _selectedConfig);
    await p.setString(_kLang, _language);
  }
}