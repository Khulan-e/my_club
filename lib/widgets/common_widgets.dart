// lib/widgets/common_widgets.dart
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_and_constants.dart';

// ─────────────────────────────────────────────────────────────
// LIQUID GLASS CARD — Glassmorphism (blur + transparency, theme-aware)
// (theme_and_constants дээрх GlassCard-аас өөр; onTap, theme-aware)
// ─────────────────────────────────────────────────────────────
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double blur;
  final double tintOpacity;
  final VoidCallback? onTap;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 16,
    this.blur = 14,
    this.tintOpacity = 0.10,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    // Light theme дээр илүү харанхуй tint ашиглана
    final isDark = c.bgDark.computeLuminance() < 0.3;
    final tintColor = isDark ? Colors.white : Colors.black;

    final inner = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tintColor.withOpacity(tintOpacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: tintColor.withOpacity(isDark ? 0.18 : 0.12),
              width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.20 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6)),
            ],
          ),
          child: child,
        ),
      ),
    );

    final wrapped = Padding(
      padding: margin ?? EdgeInsets.zero,
      child: onTap == null
          ? inner
          : Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(radius),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(radius),
                child: inner,
              ),
            ),
    );

    return wrapped;
  }
}

// ─────────────────────────────────────────────────────────────
// STARRY OVERLAY — gradient дээр тогтмол одод нэмэх
// ─────────────────────────────────────────────────────────────
class StarryOverlay extends StatelessWidget {
  final int starCount;
  final Color color;
  const StarryOverlay({super.key, this.starCount = 110, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _StarsPainter(starCount: starCount, color: color),
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  final int starCount;
  final Color color;
  _StarsPainter({required this.starCount, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42); // тогтмол үр дүнгийн төлөө
    for (int i = 0; i < starCount; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      final r  = rng.nextDouble() * 1.4 + 0.4;
      final op = rng.nextDouble() * 0.55 + 0.25;
      final paint = Paint()..color = color.withOpacity(op);
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) =>
      oldDelegate.starCount != starCount || oldDelegate.color != color;
}

// ─────────────────────────────────────────────────────────────
// PILL NAV BAR — admin + super_admin аль алинд хэрэглэнэ
// Сонгогдсон item-ийн icon бөмбөлөг pill-ээс ДЭЭГҮҮР гарсан байна.
// ─────────────────────────────────────────────────────────────
class PillNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const PillNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class PillNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<PillNavItem> items;
  final ThemeColors colors;
  const PillNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SizedBox(
        height: 78,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: colors.border.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
            ),
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (i) => _PillNavItemView(
                  item: items[i],
                  isSelected: i == selectedIndex,
                  onTap: () => onTap(i),
                  c: colors,
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillNavItemView extends StatelessWidget {
  final PillNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeColors c;
  const _PillNavItemView({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60, height: 78,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              top: isSelected ? 0 : 18,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: isSelected ? 44 : 36,
                height: isSelected ? 44 : 36,
                decoration: BoxDecoration(
                  color: isSelected ? c.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [BoxShadow(color: c.primary.withOpacity(0.45), blurRadius: 12, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  color: isSelected ? Colors.white : c.textMuted,
                  size: isSelected ? 22 : 20,
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 240),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? c.primary : c.textMuted,
                ),
                child: Text(item.label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// AppTextField
// ─────────────────────────────────────────
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int maxLines;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return TextFormField(
      controller:   controller,
      obscureText:  obscureText,
      keyboardType: keyboardType,
      maxLines:     obscureText ? 1 : maxLines,
      validator:    validator,
      style: TextStyle(color: c.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText:  label,
        hintText:   hint,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20, color: c.textMuted)
            : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

// ─────────────────────────────────────────
// AppButton
// ─────────────────────────────────────────
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final IconData? icon;
  final Color? color;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading  = false,
    this.outlined = false,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
              Text(label),
            ],
          );

    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(onPressed: loading ? null : onPressed, child: child),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: color != null ? ElevatedButton.styleFrom(backgroundColor: color) : null,
        onPressed: loading ? null : onPressed,
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────
// ErrorBanner
// ─────────────────────────────────────────
class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.coral.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.coral.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: c.coral),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
              style: TextStyle(color: c.coral, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// SectionHeader
// ─────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
        style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: c.textMuted, letterSpacing: 0.5,
        )),
    );
  }
}

// ─────────────────────────────────────────
// CategoryBadge
// ─────────────────────────────────────────
class CategoryBadge extends StatelessWidget {
  final String category;
  const CategoryBadge({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    Color color; String label;
    switch (category) {
      case 'professional':
        color = c.primary; label = 'Мэргэжлийн';
        break;
      case 'hobby':
        color = c.teal; label = 'Сонирхлын';
        break;
      case 'art':
        color = c.accent; label = 'Урлагийн';
        break;
      default:
        color = c.textMuted; label = category;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
        maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

// ─────────────────────────────────────────
// StatusBadge
// ─────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    Color color; String label; IconData icon;
    switch (status) {
      case 'approved':
        color = c.teal;  label = 'Батлагдсан';    icon = Icons.check_circle_outline_rounded;
        break;
      case 'rejected':
        color = c.coral; label = 'Татгалзсан';    icon = Icons.cancel_outlined;
        break;
      default:
        color = const Color(0xFFFFBE45); label = 'Хүлээгдэж буй'; icon = Icons.hourglass_empty_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// EmptyState
// ─────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 40, color: c.textMuted),
            ),
            const SizedBox(height: 16),
            Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textMuted, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// LoadingView
// ─────────────────────────────────────────
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Center(
      child: CircularProgressIndicator(color: c.primary, strokeWidth: 2.5),
    );
  }
}

// ─────────────────────────────────────────
// ClubCard — fixed overflow
// ─────────────────────────────────────────
class ClubCard extends StatelessWidget {
  final Map<String, dynamic> club;
  final VoidCallback onTap;

  const ClubCard({super.key, required this.club, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return LiquidGlassCard(
      radius: 16,
      blur: 18,
      tintOpacity: 0.10,
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
            // Icon + Name + Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: c.accentGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: club['logo_url'] != null && (club['logo_url'] as String).isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(club['logo_url'], fit: BoxFit.cover))
                      : const Icon(Icons.groups_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(club['name'] ?? '',
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      CategoryBadge(category: club['category'] ?? ''),
                    ],
                  ),
                ),
              ],
            ),
            // Description
            if (club['description'] != null && (club['description'] as String).isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(club['description'],
                style: TextStyle(fontSize: 11, color: c.textSecondary),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 6),
            // Rating + members
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFBE45)),
                const SizedBox(width: 2),
                Text((club['avg_rating'] ?? 0.0).toStringAsFixed(1),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFFFBE45))),
                const SizedBox(width: 8),
                Icon(Icons.people_outline, size: 13, color: c.textMuted),
                const SizedBox(width: 2),
                Text('${club['member_count'] ?? 0} гишүүн',
                  style: TextStyle(fontSize: 11, color: c.textMuted)),
              ],
            ),
          ],
        ),
    );
  }
}