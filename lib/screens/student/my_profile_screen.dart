// lib/screens/student/my_profile_screen.dart
// ignore_for_file: use_build_context_synchronously
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/theme_and_constants.dart';
import '../../widgets/common_widgets.dart';

// ─────────────────────────────────────────────────────────────
// Avatar icon-уудын жагсаалт
// ─────────────────────────────────────────────────────────────
const _avatarIcons = [
  Icons.person_rounded,
  Icons.face_rounded,
  Icons.sentiment_very_satisfied_rounded,
  Icons.school_rounded,
  Icons.star_rounded,
  Icons.rocket_launch_rounded,
  Icons.auto_awesome_rounded,
  Icons.psychology_rounded,
  Icons.eco_rounded,
  Icons.local_fire_department_rounded,
  Icons.diamond_rounded,
  Icons.bolt_rounded,
  Icons.palette_rounded,
  Icons.sports_esports_rounded,
  Icons.music_note_rounded,
  Icons.sports_basketball_rounded,
];

// ─────────────────────────────────────────────────────────────
// Avatar харуулах helper widget
// ─────────────────────────────────────────────────────────────
class AvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String initial;
  final ThemeColors c;
  final double size;

  const AvatarWidget({
    super.key,
    required this.avatarUrl,
    required this.initial,
    required this.c,
    this.size = 90,
  });

  @override
  Widget build(BuildContext context) {
    // icon:INDEX форматтай бол icon харуулна
    if (avatarUrl != null && avatarUrl!.startsWith('icon:')) {
      final idx = int.tryParse(avatarUrl!.replaceFirst('icon:', '')) ?? 0;
      final safeIdx = idx.clamp(0, _avatarIcons.length - 1);
      final colors = [c.primary, c.teal, c.accent, c.coral];
      final iconColor = colors[safeIdx % colors.length];
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: iconColor.withOpacity(0.15),
          border: Border.all(color: iconColor.withOpacity(0.4), width: 2),
        ),
        child: Icon(_avatarIcons[safeIdx], color: iconColor, size: size * 0.5),
      );
    }
    // URL байвал зураг харуулна
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Container(
        width: size, height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: ClipOval(
          child: Image.network(avatarUrl!, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _defaultAvatar()),
        ),
      );
    }
    return _defaultAvatar();
  }

  Widget _defaultAvatar() => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, gradient: c.accentGradient),
    child: Center(
      child: Text(initial,
        style: TextStyle(fontSize: size * 0.38, color: Colors.white, fontWeight: FontWeight.w700)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// MY PROFILE SCREEN
// ─────────────────────────────────────────────────────────────
class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});
  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _deptCtrl;
  bool _editing       = false;
  bool _saving        = false;
  bool _avatarLoading = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<AuthProvider>().profile;
    _nameCtrl  = TextEditingController(text: p?['full_name'] ?? '');
    _phoneCtrl = TextEditingController(text: p?['phone'] ?? '');
    _deptCtrl  = TextEditingController(text: p?['department'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _deptCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    await AuthService().updateProfile(
      userId:     auth.user!.id,
      fullName:   _nameCtrl.text.trim(),
      phone:      _phoneCtrl.text.trim(),
      department: _deptCtrl.text.trim(),
    );
    await auth.refreshProfile();
    if (mounted) setState(() { _saving = false; _editing = false; });
  }

  Future<void> _updateAvatar(String? url) async {
    setState(() => _avatarLoading = true);
    final auth = context.read<AuthProvider>();
    await supabase.from('users').update({'avatar_url': url}).eq('id', auth.user!.id);
    await auth.refreshProfile();
    if (mounted) setState(() => _avatarLoading = false);
  }

  void _showAvatarPicker() {
    final auth = context.read<AuthProvider>();
    final tp   = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: tp,
        child: _AvatarPickerSheet(
          userId:        auth.user!.id,
          currentAvatar: auth.profile?['avatar_url'],
          onChanged:     _updateAvatar,
        ),
      ),
    );
  }

  void _showThemePicker() {
    final tp = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        maxWidth: double.infinity,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: tp,
        child: const _ThemePickerSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile       = context.watch<AuthProvider>().profile;
    final themeProvider = context.watch<ThemeProvider>();
    final c             = themeProvider.colors;
    final avatarUrl     = profile?['avatar_url'] as String?;
    final name          = profile?['full_name'] ?? '';
    final initial       = name.isNotEmpty ? name[0] : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Миний профайл'),
        actions: [
          if (!_editing)
            IconButton(icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editing = true)),
          if (_editing)
            TextButton(onPressed: _saving ? null : _save,
              child: const Text('Хадгалах')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Avatar ────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showAvatarPicker,
                      child: Stack(
                        children: [
                          _avatarLoading
                              ? Container(
                                  width: 90, height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: c.primaryLight,
                                  ),
                                  child: Center(child: CircularProgressIndicator(
                                    color: c.primary, strokeWidth: 2)),
                                )
                              : AvatarWidget(avatarUrl: avatarUrl, initial: initial, c: c),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: c.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: c.bgDark, width: 2),
                                boxShadow: [BoxShadow(color: c.primary.withOpacity(0.4), blurRadius: 6)],
                              ),
                              child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary)),
                    const SizedBox(height: 4),
                    Text(profile?['email'] ?? '', style: TextStyle(color: c.textMuted, fontSize: 13)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _showThemePicker,
                      child: _ThemePreviewBadge(mode: themeProvider.mode),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _infoCard(c, 'Хувийн мэдээлэл', [
                _editing
                    ? AppTextField(controller: _nameCtrl, label: 'Нэр',
                        validator: (v) => v!.isEmpty ? 'Нэр оруулна уу' : null)
                    : _row(c, 'Нэр', profile?['full_name'] ?? '-'),
                const SizedBox(height: 10),
                _editing
                    ? AppTextField(controller: _phoneCtrl, label: 'Утас',
                        keyboardType: TextInputType.phone)
                    : _row(c, 'Утас', profile?['phone'] ?? '-'),
              ]),
              const SizedBox(height: 12),

              _infoCard(c, 'Сургалтын мэдээлэл', [
                _row(c, 'Оюутны код', profile?['student_code'] ?? '-'),
                const SizedBox(height: 8),
                _row(c, 'Сургууль', profile?['school'] ?? '-'),
                const SizedBox(height: 8),
                _editing
                    ? AppTextField(controller: _deptCtrl, label: 'Тэнхим / анги')
                    : _row(c, 'Тэнхим', profile?['department'] ?? '-'),
              ]),
              const SizedBox(height: 12),

              Card(
                child: ListTile(
                  leading: Icon(Icons.lock_outline, color: c.primary),
                  title: const Text('Нууц үг солих'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/change-password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(ThemeColors c, String title, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );

  Widget _row(ThemeColors c, String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(color: c.textMuted, fontSize: 13)),
      Text(value,  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────
// AVATAR PICKER SHEET
// ─────────────────────────────────────────────────────────────
class _AvatarPickerSheet extends StatefulWidget {
  final String userId;
  final String? currentAvatar;
  final Function(String?) onChanged;
  const _AvatarPickerSheet({required this.userId, required this.currentAvatar, required this.onChanged});
  @override
  State<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<_AvatarPickerSheet> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() => _uploading = true);
    try {
      final bytes    = await picked.readAsBytes();
      final mimeType = picked.mimeType ?? 'image/jpeg';
      final ext      = picked.name.split('.').last.toLowerCase();
      final path     = '${widget.userId}/avatar.$ext';
      await supabase.storage.from('avatars').uploadBinary(
        path, bytes,
        fileOptions: FileOptions(contentType: mimeType, upsert: true),
      );
      final url      = supabase.storage.from('avatars').getPublicUrl(path);
      final finalUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
      widget.onChanged(finalUrl);
      if (mounted) Navigator.pop(context);
    } catch (err) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Алдаа: $err')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _selectIcon(int index) async {
    widget.onChanged('icon:$index');
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Профайл зураг',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)),
            const SizedBox(height: 20),

            if (_uploading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(color: c.primary),
              )
            else ...[
              // Upload товч
              GestureDetector(
                onTap: _pickAndUpload,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: c.accentGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Зураг upload хийх',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Хуваагч
              Row(children: [
                Expanded(child: Divider(color: c.border.withOpacity(0.4))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('эсвэл icon сонгох',
                    style: TextStyle(fontSize: 12, color: c.textMuted)),
                ),
                Expanded(child: Divider(color: c.border.withOpacity(0.4))),
              ]),
              const SizedBox(height: 16),

              // Icon grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: _avatarIcons.length,
                itemBuilder: (_, i) {
                  final isSelected = widget.currentAvatar == 'icon:$i';
                  final palette    = [c.primary, c.teal, c.accent, c.coral];
                  final iconColor  = palette[i % palette.length];
                  return GestureDetector(
                    onTap: () => _selectIcon(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: isSelected ? iconColor.withOpacity(0.2) : c.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? iconColor : c.border.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: iconColor.withOpacity(0.3), blurRadius: 8)]
                            : [],
                      ),
                      child: Icon(_avatarIcons[i], color: iconColor, size: 30),
                    ),
                  );
                },
              ),

              // Зураг хасах
              if (widget.currentAvatar != null) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () { widget.onChanged(null); Navigator.pop(context); },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.coral.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline_rounded, color: c.coral, size: 18),
                        const SizedBox(width: 8),
                        Text('Зураг хасах',
                          style: TextStyle(color: c.coral, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// THEME PREVIEW BADGE
// ─────────────────────────────────────────────────────────────
class _ThemePreviewBadge extends StatelessWidget {
  final AppThemeMode mode;
  const _ThemePreviewBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    final c = ThemePalette.of(mode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: mode.accentColor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(mode.icon, size: 14, color: mode.accentColor),
          const SizedBox(width: 6),
          Text(mode.label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: mode.accentColor)),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: mode.accentColor),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// THEME PICKER SHEET
// ─────────────────────────────────────────────────────────────
class _ThemePickerSheet extends StatelessWidget {
  const _ThemePickerSheet();

  @override
  Widget build(BuildContext context) {
    final tp      = context.watch<ThemeProvider>();
    final current = tp.mode;
    final c       = tp.colors;

    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 36),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(children: [
              Icon(Icons.palette_outlined, color: c.primary, size: 20),
              const SizedBox(width: 8),
              Text('Өнгөний загвар',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)),
            ]),
            const SizedBox(height: 16),
            ...AppThemeMode.values.map((mode) {
              final isSelected = mode == current;
              final mc         = ThemePalette.of(mode);
              return _ThemeOption(
                mode: mode, colors: mc, isSelected: isSelected,
                onTap: () { tp.setTheme(mode); Navigator.pop(context); },
              );
            }),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final AppThemeMode mode;
  final ThemeColors  colors;
  final bool         isSelected;
  final VoidCallback onTap;
  const _ThemeOption({required this.mode, required this.colors, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? mode.accentColor.withOpacity(0.12) : colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? mode.accentColor.withOpacity(0.6) : colors.border.withOpacity(0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: colors.accentGradient,
              border: Border.all(color: mode.accentColor.withOpacity(0.5), width: 2),
              boxShadow: isSelected ? [BoxShadow(color: mode.accentColor.withOpacity(0.3), blurRadius: 10)] : [],
            ),
          ),
          const SizedBox(width: 14),
          Icon(mode.icon, size: 18, color: mode.accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(mode.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? mode.accentColor : colors.textPrimary,
              )),
          ),
          if (isSelected)
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(shape: BoxShape.circle, color: mode.accentColor),
              child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
            ),
        ]),
      ),
    );
  }
}