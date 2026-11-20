import 'package:flutter/material.dart';
import 'app_strings.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('mr'); // Default to Marathi for local society context

  Locale get locale => _locale;
  String get currentLanguageCode => _locale.languageCode;
  bool get isMarathi => _locale.languageCode == 'mr';

  void setLocale(Locale locale) {
    if (_locale != locale) {
      _locale = locale;
      notifyListeners();
    }
  }

  void toggleLanguage() {
    if (_locale.languageCode == 'mr') {
      _locale = const Locale('en');
    } else {
      _locale = const Locale('mr');
    }
    notifyListeners();
  }

  String tr(String key) {
    return AppStrings.get(key, _locale.languageCode);
  }
}
