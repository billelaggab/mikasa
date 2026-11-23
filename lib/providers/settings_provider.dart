import 'package:flutter/material.dart';
import 'package:mikasa/services/database_service.dart';

/// إعدادات المستخدم: المظهر، اللغة، ووضع القراءة الليلي.
///
/// كل تغيير يُحفظ فوراً في Hive، لذا تعود التفضيلات كما كانت بعد إغلاق التطبيق.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._database);

  final DatabaseService _database;

  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language_code';
  static const String _nightReadingKey = 'night_reading_mode';

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('ar');
  bool _nightReadingMode = false;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get nightReadingMode => _nightReadingMode;

  /// قراءة القيم المحفوظة (متزامنة لأن الصناديق مفتوحة مسبقاً).
  void load() {
    final String? savedTheme = _database.readString(_themeKey);
    _themeMode = switch (savedTheme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final String? savedLanguage = _database.readString(_languageKey);
    if (savedLanguage != null && (savedLanguage == 'ar' || savedLanguage == 'en')) {
      _locale = Locale(savedLanguage);
    }

    _nightReadingMode = _database.readBool(_nightReadingKey) ?? false;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
    await _database.writeSetting(_themeKey, mode.name);
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale.languageCode == locale.languageCode) {
      return;
    }
    _locale = locale;
    notifyListeners();
    await _database.writeSetting(_languageKey, locale.languageCode);
  }

  Future<void> toggleLanguage() {
    return setLocale(Locale(_locale.languageCode == 'ar' ? 'en' : 'ar'));
  }

  Future<void> setNightReadingMode(bool value) async {
    if (_nightReadingMode == value) {
      return;
    }
    _nightReadingMode = value;
    notifyListeners();
    await _database.writeSetting(_nightReadingKey, value);
  }
}
