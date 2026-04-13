// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/theme_and_constants.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
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
// ClubCard
// ─────────────────────────────────────────
class ClubCard extends StatelessWidget {
  final Map<String, dynamic> club;
  final VoidCallback onTap;

  const ClubCard({super.key, required this.club, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: c.primary.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    gradient: c.accentGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: club['logo_url'] != null && (club['logo_url'] as String).isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(club['logo_url'], fit: BoxFit.cover))
                      : const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(club['name'] ?? '',
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      CategoryBadge(category: club['category'] ?? ''),
                    ],
                  ),
                ),
              ],
            ),
            if (club['description'] != null) ...[
              const SizedBox(height: 8),
              Text(club['description'],
                style: TextStyle(fontSize: 12, color: c.textSecondary),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFBE45)),
                const SizedBox(width: 3),
                Text((club['avg_rating'] ?? 0.0).toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFFFBE45))),
                const SizedBox(width: 12),
                Icon(Icons.people_outline, size: 14, color: c.textMuted),
                const SizedBox(width: 3),
                Text('${club['member_count'] ?? 0} гишүүн',
                  style: TextStyle(fontSize: 12, color: c.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}