// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
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
    return TextFormField(
      controller:   controller,
      obscureText:  obscureText,
      keyboardType: keyboardType,
      maxLines:     obscureText ? 1 : maxLines,
      validator:    validator,
      decoration: InputDecoration(
        labelText:  label,
        hintText:   hint,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20, color: AppColors.textMuted)
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
        child: OutlinedButton(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: color != null
            ? ElevatedButton.styleFrom(backgroundColor: color)
            : null,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF7C1C1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xFFA32D2D)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
              style: const TextStyle(color: Color(0xFFA32D2D), fontSize: 13)),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
        style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: AppColors.textMuted, letterSpacing: 0.5,
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
    Color bg; Color fg; String label;
    switch (category) {
      case 'professional':
        bg = AppColors.primaryLight; fg = AppColors.primaryDark; label = 'Мэргэжлийн';
        break;
      case 'hobby':
        bg = AppColors.tealLight; fg = AppColors.teal; label = 'Сонирхлын';
        break;
      case 'art':
        bg = const Color(0xFFFBEAF0); fg = const Color(0xFF72243E); label = 'Урлагийн';
        break;
      default:
        bg = Colors.grey.shade100; fg = Colors.grey.shade700; label = category;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500)),
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
    Color bg; Color fg; String label; IconData icon;
    switch (status) {
      case 'approved':
        bg = AppColors.tealLight; fg = AppColors.teal;
        label = 'Батлагдсан'; icon = Icons.check_circle_outline_rounded;
        break;
      case 'rejected':
        bg = const Color(0xFFFCEBEB); fg = const Color(0xFFA32D2D);
        label = 'Татгалзсан'; icon = Icons.cancel_outlined;
        break;
      default: // pending
        bg = AppColors.amberLight; fg = AppColors.amber;
        label = 'Хүлээгдэж буй'; icon = Icons.hourglass_empty_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(label,
            style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500)),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
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
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

// ─────────────────────────────────────────
// ClubCard  — BorderedCard ашиглана
// ─────────────────────────────────────────
class ClubCard extends StatelessWidget {
  final Map<String, dynamic> club;
  final VoidCallback onTap;

  const ClubCard({super.key, required this.club, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BorderedCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: club['logo_url'] != null &&
                          (club['logo_url'] as String).isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(club['logo_url'], fit: BoxFit.cover))
                      : const Icon(Icons.groups_rounded,
                          color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(club['name'],
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      CategoryBadge(category: club['category']),
                    ],
                  ),
                ),
              ],
            ),
            if (club['description'] != null) ...[
              const SizedBox(height: 8),
              Text(club['description'],
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    size: 14, color: AppColors.amber),
                const SizedBox(width: 3),
                Text((club['avg_rating'] ?? 0.0).toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(width: 10),
                const Icon(Icons.people_outline,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 3),
                Text('${club['member_count'] ?? 0} гишүүн',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}