// lib/utils/theme_and_constants.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary      = Color(0xFF534AB7);
  static const primaryLight = Color(0xFFEEEDFE);
  static const primaryDark  = Color(0xFF3C3489);
  static const teal         = Color(0xFF1D9E75);
  static const tealLight    = Color(0xFFE1F5EE);
  static const coral        = Color(0xFFD85A30);
  static const coralLight   = Color(0xFFFAECE7);
  static const amber        = Color(0xFFBA7517);
  static const amberLight   = Color(0xFFFAEEDA);
  static const surface      = Color(0xFFF8F7FF);
  static const border       = Color(0xFFE8E7F5);
  static const textMuted    = Color(0xFF888780);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,

      // ── Color scheme ──────────────────────────────────────
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: Colors.white,
      ),

      // ── Typography ────────────────────────────────────────
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),

      // ── AppBar ────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:  Colors.white,
        foregroundColor:  const Color(0xFF1A1A2E),
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize:   16,
          fontWeight: FontWeight.w600,
          color:      const Color(0xFF1A1A2E),
        ),
      ),

      // ── Card ─────────────────────────────────────────────
      // Flutter 3.x: CardTheme-д shape байхгүй.
      // Card widget-д border-г clipBehavior + decoration-аар хийнэ.
      // Энд зөвхөн color, elevation, margin тохируулна.
      cardTheme: const CardThemeData(
        color:     Colors.white,
        elevation: 0,
      ),

      // ── Input decoration ──────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: const TextStyle(color: AppColors.textMuted),
      ),

      // ── ElevatedButton ────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── OutlinedButton ────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),

      // ── TextButton ────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),

      // ── Chip ─────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:  AppColors.surface,
        selectedColor:    AppColors.primaryLight,
        labelStyle:       GoogleFonts.plusJakartaSans(fontSize: 12),
        padding:          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      // ── Divider ───────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color:     AppColors.border,
        thickness: 0.8,
      ),

      // ── NavigationBar ─────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:    Colors.white,
        indicatorColor:     AppColors.primaryLight,
        labelTextStyle:     WidgetStateProperty.all(
          GoogleFonts.plusJakartaSans(fontSize: 11),
        ),
      ),

      scaffoldBackgroundColor: Colors.white,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Card-д border харуулах helper widget
// CardTheme-д shape байхгүй тул энэ widget ашиглана
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
    this.radius = 12,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  margin,
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// App Constants
// ─────────────────────────────────────────────────────────────
class AppConstants {
  static const List<Map<String, dynamic>> huisClubs = [
    // Мэргэжлийн
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
    // Сонирхлын
    {'name': 'Хүмүүнлэг уншигч',      'sub': 'Ном унших',             'cat': 'hobby',        'emoji': '📚'},
    {'name': 'Prana Yoga',            'sub': 'Йог, эрүүл мэнд',       'cat': 'hobby',        'emoji': '🧘'},
    {'name': 'Улаан загалмай',         'sub': 'Сайн дурын үйлчилгээ', 'cat': 'hobby',        'emoji': '🏥'},
    {'name': 'Unity',                 'sub': 'Нэгдэл, манлайлал',     'cat': 'hobby',        'emoji': '🤝'},
    // Урлагийн
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