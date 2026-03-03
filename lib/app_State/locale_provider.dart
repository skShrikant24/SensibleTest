import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _localeKey = 'app_locale';

/// Holds the app locale (en = English, kn = Kannada). Default is English.
/// Persists to SharedPreferences and notifies listeners so the app rebuilds.
class LocaleProvider extends ChangeNotifier {
  LocaleProvider._();
  static final LocaleProvider instance = LocaleProvider._();

  Locale _locale = const Locale('en');
  bool _initialized = false;

  Locale get locale => _locale;

  /// Language code: 'en' or 'kn'.
  String get languageCode => _locale.languageCode;

  bool get isEnglish => _locale.languageCode == 'en';
  bool get isKannada => _locale.languageCode == 'kn';

  static const Locale en = Locale('en');
  static const Locale kn = Locale('kn');
  static const List<Locale> supportedLocales = [en, kn];

  /// Call once at app startup (e.g. from main()) to load saved locale.
  Future<void> load() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code == 'kn') {
      _locale = kn;
    } else {
      _locale = en;
    }
    _initialized = true;
    notifyListeners();
  }

  /// Set app language. Persists and notifies. [locale] should be [en] or [kn].
  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode != 'en' && locale.languageCode != 'kn') return;
    if (_locale == locale) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    notifyListeners();
  }

  Future<void> setEnglish() => setLocale(en);
  Future<void> setKannada() => setLocale(kn);
}
