// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme_and_constants.dart';

enum AppThemeMode {
  light,
  darkBlue,
  darkPurple,
  whitePurple;

  String get label {
    switch (this) {
      case AppThemeMode.light:       return 'Цагаан';
      case AppThemeMode.darkBlue:    return 'Dark Blue';
      case AppThemeMode.darkPurple:  return 'Dark Purple';
      case AppThemeMode.whitePurple: return 'White Purple';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeMode.light:       return Icons.light_mode_rounded;
      case AppThemeMode.darkBlue:    return Icons.nightlight_round;
      case AppThemeMode.darkPurple:  return Icons.auto_awesome;
      case AppThemeMode.whitePurple: return Icons.color_lens_outlined;
    }
  }

  Color get previewColor {
    switch (this) {
      case AppThemeMode.light:       return const Color(0xFFEEEEFF);
      case AppThemeMode.darkBlue:    return const Color(0xFF0C1028);
      case AppThemeMode.darkPurple:  return const Color(0xFF14102A);
      case AppThemeMode.whitePurple: return const Color(0xFFF5F0FF);
    }
  }

  Color get accentColor {
    switch (this) {
      case AppThemeMode.light:       return const Color(0xFF5B54E8);
      case AppThemeMode.darkBlue:    return const Color(0xFF6C63FF);
      case AppThemeMode.darkPurple:  return const Color(0xFFB06BFF);
      case AppThemeMode.whitePurple: return const Color(0xFF9B59B6);
    }
  }
}

class ThemeProvider extends ChangeNotifier {
  static const _key = 'app_theme_mode';
  AppThemeMode _mode = AppThemeMode.darkBlue;

  AppThemeMode get mode => _mode;

  /// Light theme-үүд: light, whitePurple
  bool get isDark =>
      _mode == AppThemeMode.darkBlue || _mode == AppThemeMode.darkPurple;

  ThemeData get themeData => AppTheme.buildTheme(_mode);
  ThemeColors get colors  => ThemePalette.of(_mode);

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved != null) {
        _mode = AppThemeMode.values.firstWhere(
          (m) => m.name == saved,
          orElse: () => AppThemeMode.darkBlue,
        );
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setTheme(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {}
  }
}