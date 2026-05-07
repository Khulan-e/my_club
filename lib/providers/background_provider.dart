// lib/providers/background_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────
// 10 ширхэг preset background — gradient + optional star overlay
// ─────────────────────────────────────────────────────────────
class BgPreset {
  final String key;
  final String name;
  final List<Color> colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final bool hasStars;

  const BgPreset({
    required this.key,
    required this.name,
    required this.colors,
    this.begin = Alignment.topLeft,
    this.end   = Alignment.bottomRight,
    this.hasStars = false,
  });

  LinearGradient get gradient => LinearGradient(begin: begin, end: end, colors: colors);
}

const kBgPresets = <BgPreset>[
  BgPreset(
    key: 'theme',
    name: 'Үндсэн загвар',
    colors: [Color(0xFF080816), Color(0xFF0C1028), Color(0xFF140A28)],
  ),
  BgPreset(
    key: 'holographic',
    name: 'Холограм',
    colors: [Color(0xFFFFD6F5), Color(0xFFE0CFFF), Color(0xFFCDE7FF), Color(0xFFFFE3F1)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  ),
  BgPreset(
    key: 'starry',
    name: 'Одтой шөнө',
    colors: [Color(0xFF1B0A45), Color(0xFF3F2196), Color(0xFF1A0A48)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    hasStars: true,
  ),
  BgPreset(
    key: 'aurora',
    name: 'Туяа',
    colors: [Color(0xFF00C9A7), Color(0xFF845EC2), Color(0xFF2E1A6B)],
    begin: Alignment.topRight, end: Alignment.bottomLeft,
  ),
  BgPreset(
    key: 'sunset',
    name: 'Нар жаргах',
    colors: [Color(0xFFFF6E7F), Color(0xFFBC4E9C), Color(0xFF5B1F8A)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  ),
  BgPreset(
    key: 'ocean',
    name: 'Далайн гүн',
    colors: [Color(0xFF06283D), Color(0xFF1363DF), Color(0xFF47B5FF)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  ),
  BgPreset(
    key: 'galaxy',
    name: 'Галактик',
    colors: [Color(0xFF000000), Color(0xFF3A0CA3), Color(0xFFF72585)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    hasStars: true,
  ),
  BgPreset(
    key: 'mint',
    name: 'Минт',
    colors: [Color(0xFF0D2E25), Color(0xFF00D9A6), Color(0xFF7FFFD4)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  ),
  BgPreset(
    key: 'lavender',
    name: 'Лавандар',
    colors: [Color(0xFFE0B7FF), Color(0xFFB06BFF), Color(0xFF6C2BD9)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  ),
  BgPreset(
    key: 'forest',
    name: 'Ой',
    colors: [Color(0xFF0B3D2E), Color(0xFF1B5E20), Color(0xFF2E7D32)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  ),
  BgPreset(
    key: 'cosmic',
    name: 'Cosmic dust',
    colors: [Color(0xFF050017), Color(0xFF240046), Color(0xFFC77DFF)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    hasStars: true,
  ),
  // ─── шинэ 10 загвар ──────────────────────────────────
  BgPreset(
    key: 'purple_haze',
    name: 'Нил ягаан утаа',
    colors: [Color(0xFF1A0033), Color(0xFF4A1A78), Color(0xFFB388FF)],
    begin: Alignment.topRight, end: Alignment.bottomLeft,
  ),
  BgPreset(
    key: 'cosmic_earth',
    name: 'Сансрын дэлхий',
    colors: [Color(0xFF000000), Color(0xFF1A0046), Color(0xFF6A11CB)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    hasStars: true,
  ),
  BgPreset(
    key: 'magenta_dust',
    name: 'Magenta тоос',
    colors: [Color(0xFF1A0022), Color(0xFF6B0F8C), Color(0xFFD500F9)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    hasStars: true,
  ),
  BgPreset(
    key: 'pastel_dream',
    name: 'Пастел зүүд',
    colors: [Color(0xFFFFD3E0), Color(0xFFD4C5F9), Color(0xFFC8E7FF)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  ),
  BgPreset(
    key: 'soft_clouds',
    name: 'Зөөлөн үүл',
    colors: [Color(0xFFF8F9FE), Color(0xFFE8EAF6), Color(0xFFD1D9E8)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  ),
  BgPreset(
    key: 'cyber_neon',
    name: 'Cyber neon',
    colors: [Color(0xFF000428), Color(0xFF004E92), Color(0xFF00D4FF)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  ),
  BgPreset(
    key: 'rose_gold',
    name: 'Rose gold',
    colors: [Color(0xFF642B73), Color(0xFFC6426E), Color(0xFFFFB199)],
    begin: Alignment.topRight, end: Alignment.bottomLeft,
  ),
  BgPreset(
    key: 'midnight_ocean',
    name: 'Шөнийн далай',
    colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  ),
  BgPreset(
    key: 'peach_sunrise',
    name: 'Тоор үүр',
    colors: [Color(0xFFFFA17F), Color(0xFFFFC796), Color(0xFFFCD0BA)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  ),
  BgPreset(
    key: 'emerald_glass',
    name: 'Emerald шил',
    colors: [Color(0xFF134E5E), Color(0xFF1FB59A), Color(0xFF71B280)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  ),
];

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────
class BackgroundProvider extends ChangeNotifier {
  static const _prefKey = 'app_bg_preset_key';

  /// 'theme' = ThemeProvider-ийн bgGradient ашигла
  String _key = 'theme';
  String get key => _key;

  BgPreset get preset =>
      kBgPresets.firstWhere((p) => p.key == _key, orElse: () => kBgPresets.first);

  /// 'theme' гэдэг нь default theme-ийн градиент ашиглах гэсэн утгатай
  bool get useThemeDefault => _key == 'theme';

  BackgroundProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _key = prefs.getString(_prefKey) ?? 'theme';
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setBackground(String key) async {
    if (_key == key) return;
    _key = key;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, key);
    } catch (_) {}
  }
}
