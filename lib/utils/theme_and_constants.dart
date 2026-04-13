// lib/utils/theme_and_constants.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_club/providers/theme_provider.dart';

// ─────────────────────────────────────────────────────────────
// APPCOLORS — backward compat (darkBlue-ийн өнгө)
// ─────────────────────────────────────────────────────────────
class AppColors {
  static const primary       = Color(0xFF6C63FF);
  static const primaryLight  = Color(0xFF2A2650);
  static const primaryDark   = Color(0xFF4A42D4);
  static const teal          = Color(0xFF00D9A6);
  static const tealLight     = Color(0xFF0D2E25);
  static const coral         = Color(0xFFFF6B6B);
  static const coralLight    = Color(0xFF2E1A1A);
  static const amber         = Color(0xFFFFBE45);
  static const amberLight    = Color(0xFF2E2510);
  static const cyan          = Color(0xFF00D4FF);
  static const pink          = Color(0xFFFF6EC7);
  static const bgDark        = Color(0xFF080816);
  static const bgCard        = Color(0xFF10102A);
  static const surface       = Color(0xFF161630);
  static const border        = Color(0xFF252555);
  static const textPrimary   = Color(0xFFF0F0FF);
  static const textSecondary = Color(0xFF9090B0);
  static const textMuted     = Color(0xFF5A5A8A);

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF080816), Color(0xFF0C1028), Color(0xFF140A28)],
  );
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A1B6C), Color(0xFF1A3A6C), Color(0xFF0A2848)],
  );
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
  );
  static LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.02)],
  );
}

// ─────────────────────────────────────────────────────────────
// THEME COLORS — нэг theme-ийн бүх өнгө
// ─────────────────────────────────────────────────────────────
class ThemeColors {
  final Color primary;
  final Color primaryLight;
  final Color bgDark;
  final Color bgCard;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color teal;
  final Color coral;
  final Color cyan;
  final LinearGradient bgGradient;
  final LinearGradient headerGradient;
  final LinearGradient accentGradient;
  final LinearGradient glassGradient;

  const ThemeColors({
    required this.primary,
    required this.primaryLight,
    required this.bgDark,
    required this.bgCard,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.teal,
    required this.coral,
    required this.cyan,
    required this.bgGradient,
    required this.headerGradient,
    required this.accentGradient,
    required this.glassGradient,
  });
}

// ─────────────────────────────────────────────────────────────
// THEME PALETTE — 4 theme
// ─────────────────────────────────────────────────────────────
class ThemePalette {
  // ── LIGHT (Цагаан) ─────────────────────────────────────────
  static const ThemeColors light = ThemeColors(
    primary:       Color(0xFF5B54E8),
    primaryLight:  Color(0xFFEEEDFF),
    bgDark:        Color(0xFFF5F5FF),
    bgCard:        Color(0xFFFFFFFF),
    surface:       Color(0xFFF0F0FA),
    border:        Color(0xFFDDDDF0),
    textPrimary:   Color(0xFF1A1A3A),
    textSecondary: Color(0xFF4A4A7A),
    textMuted:     Color(0xFF8A8AAA),
    accent:        Color(0xFF00B4D8),
    teal:          Color(0xFF00B4A6),
    coral:         Color(0xFFEF5350),
    cyan:          Color(0xFF00B4D8),
    bgGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF5F5FF), Color(0xFFEEEEFF), Color(0xFFE8E8FF)],
    ),
    headerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFDDDDFF), Color(0xFFCCDDFF), Color(0xFFBBCCFF)],
    ),
    accentGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF5B54E8), Color(0xFF00B4D8)],
    ),
    glassGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x14000000), Color(0x06000000)],
    ),
  );

  // ── DARK BLUE ──────────────────────────────────────────────
  static const ThemeColors darkBlue = ThemeColors(
    primary:       Color(0xFF6C63FF),
    primaryLight:  Color(0xFF2A2650),
    bgDark:        Color(0xFF080816),
    bgCard:        Color(0xFF10102A),
    surface:       Color(0xFF161630),
    border:        Color(0xFF252555),
    textPrimary:   Color(0xFFF0F0FF),
    textSecondary: Color(0xFF9090B0),
    textMuted:     Color(0xFF5A5A8A),
    accent:        Color(0xFF00D4FF),
    teal:          Color(0xFF00D9A6),
    coral:         Color(0xFFFF6B6B),
    cyan:          Color(0xFF00D4FF),
    bgGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF080816), Color(0xFF0C1028), Color(0xFF140A28)],
    ),
    headerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2A1B6C), Color(0xFF1A3A6C), Color(0xFF0A2848)],
    ),
    accentGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
    ),
    glassGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x14FFFFFF), Color(0x05FFFFFF)],
    ),
  );

  // ── DARK PURPLE ────────────────────────────────────────────
  static const ThemeColors darkPurple = ThemeColors(
    primary:       Color(0xFFB06BFF),
    primaryLight:  Color(0xFF2D1A4A),
    bgDark:        Color(0xFF0E0818),
    bgCard:        Color(0xFF180F2A),
    surface:       Color(0xFF1E1432),
    border:        Color(0xFF3A2560),
    textPrimary:   Color(0xFFF5F0FF),
    textSecondary: Color(0xFFAA90CC),
    textMuted:     Color(0xFF6A508A),
    accent:        Color(0xFFFF6EC7),
    teal:          Color(0xFF00D9A6),
    coral:         Color(0xFFFF6B6B),
    cyan:          Color(0xFFDA8FFF),
    bgGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0E0818), Color(0xFF14102A), Color(0xFF1A0A30)],
    ),
    headerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF3A1B6C), Color(0xFF2A1A5C), Color(0xFF1A0A48)],
    ),
    accentGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFB06BFF), Color(0xFFFF6EC7)],
    ),
    glassGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x14FFFFFF), Color(0x05FFFFFF)],
    ),
  );

  // ── WHITE PURPLE ───────────────────────────────────────────
  static const ThemeColors whitePurple = ThemeColors(
    primary:       Color(0xFF9B59B6),
    primaryLight:  Color(0xFFF0E6FF),
    bgDark:        Color(0xFFFAF5FF),
    bgCard:        Color(0xFFFFFFFF),
    surface:       Color(0xFFF3EAFF),
    border:        Color(0xFFE0D0F5),
    textPrimary:   Color(0xFF2D1B4E),
    textSecondary: Color(0xFF6A4A8A),
    textMuted:     Color(0xFFAA90C0),
    accent:        Color(0xFFDA8FFF),
    teal:          Color(0xFF00B4A6),
    coral:         Color(0xFFEF5350),
    cyan:          Color(0xFFB06BFF),
    bgGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFAF5FF), Color(0xFFF3EAFF), Color(0xFFEDE0FF)],
    ),
    headerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE8D5FF), Color(0xFFD5C0F5), Color(0xFFC8B0F0)],
    ),
    accentGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF9B59B6), Color(0xFFDA8FFF)],
    ),
    glassGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x14000000), Color(0x06000000)],
    ),
  );

  static ThemeColors of(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:       return light;
      case AppThemeMode.darkBlue:    return darkBlue;
      case AppThemeMode.darkPurple:  return darkPurple;
      case AppThemeMode.whitePurple: return whitePurple;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// APP THEME — ThemeData builder
// ─────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get dark  => buildTheme(AppThemeMode.darkBlue);
  static ThemeData get light => buildTheme(AppThemeMode.light);

  static ThemeData buildTheme(AppThemeMode mode) {
    final c       = ThemePalette.of(mode);
    final isLight = mode == AppThemeMode.light || mode == AppThemeMode.whitePurple;
    final base    = isLight ? ThemeData.light() : ThemeData.dark();

    return ThemeData(
      useMaterial3: true,
      brightness: isLight ? Brightness.light : Brightness.dark,
      colorScheme: isLight
          ? ColorScheme.light(
              primary: c.primary,
              secondary: c.accent,
              surface: c.surface,
              error: c.coral,
            )
          : ColorScheme.dark(
              primary: c.primary,
              secondary: c.accent,
              surface: c.surface,
              error: c.coral,
            ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: c.textPrimary,
        displayColor: c.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: c.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 17, fontWeight: FontWeight.w700, color: c.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: c.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.border.withOpacity(0.4)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.coral),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: c.textMuted),
        hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          side: BorderSide(color: c.primary.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.accent),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.primaryLight,
        selectedColor: c.primary.withOpacity(0.3),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: c.textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.border.withOpacity(0.3)),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border.withOpacity(0.3), thickness: 0.8),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.bgDark.withOpacity(0.95),
        indicatorColor: c.primary.withOpacity(0.15),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 11, color: c.primary, fontWeight: FontWeight.w600);
          }
          return GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: c.primary, size: 22);
          }
          return IconThemeData(color: c.textMuted, size: 22);
        }),
      ),
      scaffoldBackgroundColor: c.bgDark,
      dialogTheme: DialogThemeData(
        backgroundColor: c.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surface,
        contentTextStyle: TextStyle(color: c.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.bgCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GLASS CARD — theme-aware
// ─────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double blur;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 16,
    this.blur = 10,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.glassGradient,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: borderColor ?? Colors.white.withOpacity(0.08),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BORDERED CARD
// ─────────────────────────────────────────────────────────────
class BorderedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;

  const BorderedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 14,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? AppColors.bgCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border.withOpacity(0.4)),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GRADIENT BACKGROUND — theme-aware
// ─────────────────────────────────────────────────────────────
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // ThemeProvider байвал тэнийх, байхгүй бол default
    ThemeColors c;
    try {
      final tp = context.findAncestorWidgetOfExactType<GradientBackground>();
      // Provider-оос авна
      c = AppColors.bgDark == const Color(0xFF080816)
          ? ThemePalette.darkBlue
          : ThemePalette.darkBlue;
    } catch (_) {
      c = ThemePalette.darkBlue;
    }
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GLOW ICON
// ─────────────────────────────────────────────────────────────
class GlowIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const GlowIcon({super.key, required this.icon, required this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.2), blurRadius: 12, spreadRadius: 0),
        ],
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// App Constants
// ─────────────────────────────────────────────────────────────
class AppConstants {
  static const List<Map<String, dynamic>> huisClubs = [
    {'name': 'Innovengers',           'sub': 'График дизайн',         'cat': 'professional', 'emoji': '🎨'},
    {'name': 'NUTS',                  'sub': 'Программ хангамж',      'cat': 'professional', 'emoji': '💻'},
    {'name': 'Орчуулгын клуб',        'sub': 'Хэл шинжлэл',          'cat': 'professional', 'emoji': '🌐'},
    {'name': 'Walky Talky',           'sub': 'Харилцаа, яриа',        'cat': 'professional', 'emoji': '🎙'},
    {'name': 'Алтан үзэг',            'sub': 'Сэтгүүл зүй',          'cat': 'professional', 'emoji': '✍️'},
    {'name': 'Эдийн засгийн клуб',    'sub': 'Эдийн засаг',           'cat': 'professional', 'emoji': '📊'},
    {'name': 'TAX',                   'sub': 'Татвар, мэдүүлэг',      'cat': 'professional', 'emoji': '📋'},
    {'name': 'S-R 120',               'sub': 'Сэтгэл зүй',            'cat': 'professional', 'emoji': '🧠'},
    {'name': 'FMS',                   'sub': 'Санхүү & Менежмент',    'cat': 'professional', 'emoji': '💰'},
    {'name': 'WOB',                   'sub': 'Бизнес',                'cat': 'professional', 'emoji': '📈'},
    {'name': 'MCM',                   'sub': 'Олон улсын харилцаа',   'cat': 'professional', 'emoji': '🌍'},
    {'name': 'ITBA',                  'sub': 'IT / Бизнес шинжилгээ', 'cat': 'professional', 'emoji': '🔍'},
    {'name': 'Angarag',               'sub': 'Стартап, инновац',      'cat': 'professional', 'emoji': '🚀'},
    {'name': 'Алтан гэрэгэ',          'sub': 'Мэргэжлийн хөгжил',    'cat': 'professional', 'emoji': '⭐'},
    {'name': 'Хүмүүнлэг уншигч',      'sub': 'Ном унших',             'cat': 'hobby',        'emoji': '📚'},
    {'name': 'Prana Yoga',            'sub': 'Йог, эрүүл мэнд',       'cat': 'hobby',        'emoji': '🧘'},
    {'name': 'Улаан загалмай',         'sub': 'Сайн дурын үйлчилгээ', 'cat': 'hobby',        'emoji': '🏥'},
    {'name': 'Unity',                 'sub': 'Нэгдэл, манлайлал',     'cat': 'hobby',        'emoji': '🤝'},
    {'name': 'Үелзэл',                'sub': 'Бүжиг, урлаг',          'cat': 'art',          'emoji': '💃'},
    {'name': 'Уянгын урлагийн клуб',  'sub': 'Дуу, хөгжим',           'cat': 'art',          'emoji': '🎵'},
  ];

  static const schools = [
    'Хүмүүнлэгийн ухааны их сургууль',
    'Бизнесийн сургууль',
    'Байгалийн ухааны сургууль',
    'Нийгмийн ухааны сургууль',
    'Хуулийн сургууль',
  ];
}