// lib/screens/admin/admin_dashboard_screen.dart
// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/theme_and_constants.dart';
import '../../widgets/common_widgets.dart';
import '../student/my_profile_screen.dart'; // AvatarWidget, _AvatarPickerSheet

// ══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  String? _managedClubId;
  String? _managedClubName;
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadClub(); }

  Future<void> _loadClub() async {
    final auth   = context.read<AuthProvider>();
    final clubId = auth.managedClubId;
    if (clubId == null) { setState(() => _loading = false); return; }
    final club = await ClubService().getClub(clubId);
    if (mounted) setState(() {
      _managedClubId   = clubId;
      _managedClubName = club?['name'];
      _loading         = false;
    });
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    if (_loading) return const Scaffold(body: LoadingView());
    if (_managedClubId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Клубийн тэргүүн')),
        body: const EmptyState(message: 'Танд хуваарилагдсан клуб байхгүй байна',
          icon: Icons.groups_outlined),
      );
    }

    // 5 tab: Dashboard | Клуб | Профайл | Контент | Цаг
    // (Сэтгэгдэл → Dashboard, Хүсэлт → Профайл, Чат → FAB)
    final pages = [
      _DashboardTab(clubId: _managedClubId!),
      _ClubsTab(clubId: _managedClubId!, clubName: _managedClubName ?? ''),
      _ProfileTab(clubId: _managedClubId!, onSignOut: _signOut),
      _ContentTab(clubId: _managedClubId!),
      _HoursTab(clubId: _managedClubId!),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_managedClubName ?? 'Клубийн тэргүүн'),
        actions: [_ThemeSwitchButton()],
      ),
      body: pages[_selectedIndex],
      // Dashboard tab дээр л chat FAB харуулна
      floatingActionButton: _selectedIndex == 0
          ? _ChatFAB(clubId: _managedClubId!, clubName: _managedClubName ?? '')
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _AnimatedPillNavBar(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CHAT FLOATING ACTION BUTTON — Dashboard дээр харагдах
// ══════════════════════════════════════════════════════════════
class _ChatFAB extends StatelessWidget {
  final String clubId, clubName;
  const _ChatFAB({required this.clubId, required this.clubName});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return GestureDetector(
      onTap: () {
        final tp = context.read<ThemeProvider>();
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: tp,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Чат'),
                actions: [_ThemeSwitchButton()],
              ),
              body: _AdminChatScreen(clubId: clubId, clubName: clubName),
            ),
          ),
        ));
      },
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          gradient: c.accentGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: c.primary.withOpacity(0.45), blurRadius: 18, offset: const Offset(0, 6)),
          ],
        ),
        child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ANIMATED PILL NAV BAR — раисд бөмбөлөгтэй
// ══════════════════════════════════════════════════════════════
const _adminNavItems = [
  PillNavItem(icon: Icons.home_outlined,      selectedIcon: Icons.home_rounded,     label: 'Нүүр'),
  PillNavItem(icon: Icons.groups_outlined,    selectedIcon: Icons.groups_rounded,   label: 'Клуб'),
  PillNavItem(icon: Icons.person_outline,     selectedIcon: Icons.person_rounded,   label: 'Профайл'),
  PillNavItem(icon: Icons.campaign_outlined,  selectedIcon: Icons.campaign_rounded, label: 'Контент'),
  PillNavItem(icon: Icons.schedule_outlined,  selectedIcon: Icons.schedule_rounded, label: 'Цаг'),
];

class _AnimatedPillNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _AnimatedPillNavBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return PillNavBar(
      selectedIndex: selectedIndex,
      onTap: onTap,
      items: _adminNavItems,
      colors: c,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// THEME SWITCH BUTTON
// ══════════════════════════════════════════════════════════════
class _ThemeSwitchButton extends StatelessWidget {
  const _ThemeSwitchButton();
  static const _modes = AppThemeMode.values;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final c  = tp.colors;
    final current = tp.mode;
    return GestureDetector(
      onTap: () { final ni = (_modes.indexOf(current) + 1) % _modes.length; tp.setTheme(_modes[ni]); },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.primary.withOpacity(0.25))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(current.icon, size: 16, color: c.primary),
          const SizedBox(width: 4),
          Text(current.label, style: TextStyle(fontSize: 11, color: c.primary, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PROFILE TAB — avatar picker + sign out
// ══════════════════════════════════════════════════════════════
class _ProfileTab extends StatefulWidget {
  final String clubId;
  final VoidCallback onSignOut;
  const _ProfileTab({required this.clubId, required this.onSignOut});
  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _avatarLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) { setState(() => _loading = false); return; }
    final res = await supabase.from('users').select().eq('id', uid).maybeSingle();
    if (mounted) setState(() { _profile = res; _loading = false; });
  }

  /// Super admin-руу хүсэлт илгээх dialog
  void _showSuperAdminRequest() {
    final tp = context.read<ThemeProvider>();
    final ctrl = TextEditingController();
    String type = 'general';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => ChangeNotifierProvider.value(
        value: tp,
        child: StatefulBuilder(
          builder: (ctx, setS) {
            final c = ctx.watch<ThemeProvider>().colors;
            return Container(
              decoration: BoxDecoration(
                color: c.bgCard,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
                    )),
                    Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(gradient: c.accentGradient, shape: BoxShape.circle),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Super admin-руу хүсэлт',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary))),
                    ]),
                    const SizedBox(height: 16),
                    Text('Төрөл',
                      style: TextStyle(fontSize: 12, color: c.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(children: [
                      _typeChip(c, 'Ерөнхий', 'general', type, (v) => setS(() => type = v)),
                      const SizedBox(width: 8),
                      _typeChip(c, 'Гомдол', 'complaint', type, (v) => setS(() => type = v)),
                      const SizedBox(width: 8),
                      _typeChip(c, 'Санал', 'suggestion', type, (v) => setS(() => type = v)),
                    ]),
                    const SizedBox(height: 16),
                    Text('Хүсэлтийн агуулга',
                      style: TextStyle(fontSize: 12, color: c.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    AppTextField(controller: ctrl, label: 'Дэлгэрэнгүй бичнэ үү...', maxLines: 5),
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, child: ElevatedButton.icon(
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Илгээх'),
                      onPressed: () async {
                        final text = ctrl.text.trim();
                        if (text.isEmpty) return;
                        final uid = supabase.auth.currentUser?.id;
                        if (uid == null) return;
                        try {
                          await supabase.from('admin_requests').insert({
                            'from_uid':  uid,
                            'club_id':   widget.clubId,
                            'type':      type,
                            'message':   text,
                            'status':    'pending',
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Хүсэлт илгээгдлээ')));
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Алдаа: $e')));
                        }
                      },
                    )),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _typeChip(ThemeColors c, String label, String value, String current, ValueChanged<String> onTap) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? c.primary.withOpacity(0.18) : c.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? c.primary : c.border.withOpacity(0.3)),
        ),
        child: Text(label,
          style: TextStyle(
            color: isSelected ? c.primary : c.textPrimary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _updateAvatar(String? url) async {
    setState(() => _avatarLoading = true);
    final uid = supabase.auth.currentUser?.id;
    if (uid != null) await supabase.from('users').update({'avatar_url': url}).eq('id', uid);
    await _load();
    if (mounted) setState(() => _avatarLoading = false);
  }

  void _showAvatarPicker() {
    final tp = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: tp,
        child: _AvatarPickerSheet(
          userId: supabase.auth.currentUser?.id ?? '',
          currentAvatar: _profile?['avatar_url'],
          onChanged: _updateAvatar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    if (_loading) return const LoadingView();

    final avatarUrl = _profile?['avatar_url'] as String?;
    final name      = (_profile?['full_name'] ?? '').toString();
    final initial   = name.isNotEmpty ? name[0] : '?';
    final email     = supabase.auth.currentUser?.email ?? '';
    final phone     = (_profile?['phone'] ?? '').toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(children: [
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showAvatarPicker,
          child: Stack(children: [
            _avatarLoading
                ? Container(width: 88, height: 88,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: c.primaryLight),
                    child: Center(child: CircularProgressIndicator(color: c.primary, strokeWidth: 2)))
                : AvatarWidget(avatarUrl: avatarUrl, initial: initial, c: c, size: 88),
            Positioned(bottom: 0, right: 0,
              child: Container(width: 26, height: 26,
                decoration: BoxDecoration(
                  color: c.primary, shape: BoxShape.circle,
                  border: Border.all(color: c.bgDark, width: 2)),
                child: const Icon(Icons.edit_rounded, size: 13, color: Colors.white))),
          ]),
        ),
        const SizedBox(height: 14),
        Text(name.isEmpty ? 'Клубийн тэргүүн' : name,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.textPrimary)),
        const SizedBox(height: 4),
        if (email.isNotEmpty)
          Text(email, style: TextStyle(color: c.textSecondary, fontSize: 13)),
        if (phone.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(phone, style: TextStyle(color: c.textMuted, fontSize: 12)),
        ],
        const SizedBox(height: 24),

        _menuItem(c, Icons.person_outline, 'Профайл засах',
          () async {
            await Navigator.pushNamed(context, '/profile');
            _load();
          }),
        _menuItem(c, Icons.admin_panel_settings_outlined, 'Super admin-руу хүсэлт',
          _showSuperAdminRequest),
        _menuItem(c, Icons.lock_outline, 'Нууц үг солих',
          () => Navigator.pushNamed(context, '/change-password')),
        const SizedBox(height: 8),
        Divider(color: c.border.withOpacity(0.3)),
        const SizedBox(height: 8),
        _menuItem(c, Icons.logout, 'Гарах', widget.onSignOut, color: c.coral),
      ]),
    );
  }

  Widget _menuItem(ThemeColors c, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final itemColor = color ?? c.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LiquidGlassCard(
        radius: 14,
        blur: 18,
        tintOpacity: 0.10,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(
                color: itemColor.withOpacity(0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: itemColor.withOpacity(0.25))),
              child: Icon(icon, color: itemColor, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Text(label,
              style: TextStyle(
                fontSize: 14,
                color: color ?? c.textPrimary,
                fontWeight: FontWeight.w600))),
            if (color == null)
              Icon(Icons.chevron_right, color: c.textMuted, size: 18),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ADMIN CHAT SCREEN  (AI + DM + Группын чат)
// ══════════════════════════════════════════════════════════════
class _AdminChatScreen extends StatefulWidget {
  final String clubId, clubName;
  const _AdminChatScreen({required this.clubId, required this.clubName});
  @override
  State<_AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<_AdminChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Column(children: [
      Container(
        color: c.bgCard,
        child: TabBar(
          controller: _tabCtrl,
          labelColor: c.primary,
          unselectedLabelColor: c.textMuted,
          indicatorColor: c.primary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.smart_toy_outlined, size: 16), text: 'AI'),
            Tab(icon: Icon(Icons.chat_bubble_outline, size: 16), text: 'Мессеж'),
            Tab(icon: Icon(Icons.group_outlined, size: 16), text: 'Групп'),
          ],
        ),
      ),
      Expanded(child: TabBarView(
        controller: _tabCtrl,
        children: [
          _AdminAiTab(clubId: widget.clubId, clubName: widget.clubName),
          const _AdminDmTab(),
          _AdminGroupTab(clubId: widget.clubId, clubName: widget.clubName),
        ],
      )),
    ]);
  }
}

// ──────────────────────────────────────────────────────────────
// AI TAB (клуб контекст ашиглана)
// ──────────────────────────────────────────────────────────────
class _AdminAiTab extends StatefulWidget {
  final String clubId, clubName;
  const _AdminAiTab({required this.clubId, required this.clubName});
  @override
  State<_AdminAiTab> createState() => _AdminAiTabState();
}

class _AdminAiTabState extends State<_AdminAiTab> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;
  String _systemPrompt = '';

  static const _edgeFnUrl = 'https://vmglqlkuuijfilpfnves.supabase.co/functions/v1/gemini-chat';

  @override
  void initState() { super.initState(); _loadContext(); }

  Future<void> _loadContext() async {
    try {
      final club = await ClubService().getClub(widget.clubId);
      final members = await supabase.from('club_memberships')
          .select('id').eq('club_id', widget.clubId).eq('status', 'approved');
      final pending = await supabase.from('join_requests')
          .select('id').eq('club_id', widget.clubId).eq('status', 'pending');
      final events  = await supabase.from('events')
          .select('title, event_date, hours').eq('club_id', widget.clubId)
          .order('event_date', ascending: true).limit(5);
      final eventStr = (events as List).map((e) => e['title']).join(', ');
      if (mounted) setState(() {
        _systemPrompt =
          'Та ХУИС-ийн ClubHub апп-ийн ${widget.clubName} клубийн тэргүүний AI туслах юм. '
          'Клубийн тухай: ${club?['description'] ?? ''}. '
          'Гишүүн тоо: ${(members as List).length}. '
          'Хүлээгдэж буй хүсэлт: ${(pending as List).length}. '
          'Ирэх арга хэмжээ: $eventStr. '
          'Клуб удирдлага, арга хэмжээ зохион байгуулах, гишүүд удирдах, '
          'мэдээ нийтлэх зэрэг асуултад тусална. Монгол хэлээр, найрсаг, товч хариулна.';
      });
    } catch (_) {}
  }

  Future<void> _send([String? quick]) async {
    final text = quick ?? _msgCtrl.text.trim();
    if (text.isEmpty || _loading) return;
    _msgCtrl.clear();
    setState(() { _messages.add({'role': 'user', 'content': text}); _loading = true; });
    _scrollToBottom();
    try {
      final contents = [
        {'role': 'user', 'parts': [{'text': _systemPrompt}]},
        {'role': 'model', 'parts': [{'text': 'Ойлголоо!'}]},
        ..._messages.map((m) => {'role': m['role'] == 'user' ? 'user' : 'model', 'parts': [{'text': m['content']!}]}),
      ];
      final res = await http.post(Uri.parse(_edgeFnUrl),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode({'contents': contents}));
      if (res.statusCode == 200) {
        final reply = jsonDecode(res.body)['reply'] as String? ?? 'Хариулт олдсонгүй';
        if (mounted) setState(() { _messages.add({'role': 'assistant', 'content': reply}); _loading = false; });
      } else throw Exception('${res.statusCode}');
    } catch (_) {
      if (mounted) setState(() { _messages.add({'role': 'assistant', 'content': 'Холболтын алдаа гарлаа.'}); _loading = false; });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  });

  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Column(children: [
      Expanded(
        child: _messages.isEmpty ? _buildWelcome(c) : ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          itemCount: _messages.length + (_loading ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == _messages.length) return _buildTyping(c);
            final m = _messages[i];
            return _buildBubble(m['content']!, m['role'] == 'user', c);
          },
        ),
      ),
      _buildInput(c, context),
    ]);
  }

  Widget _buildWelcome(ThemeColors c) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(children: [
      const SizedBox(height: 16),
      Container(width: 72, height: 72,
        decoration: BoxDecoration(gradient: c.accentGradient, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: c.primary.withOpacity(0.3), blurRadius: 20)]),
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 36)),
      const SizedBox(height: 14),
      Text('Клубийн тэргүүн AI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.textPrimary)),
      const SizedBox(height: 8),
      Text('Клубийн удирдлага, арга хэмжээ, мэдээ нийтлэх талаар асуугаарай',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: c.textMuted, height: 1.5)),
      const SizedBox(height: 24),
      ...[
        (Icons.people_alt_outlined,      const Color(0xFF4F8EF7), 'Гишүүдийг хэрхэн идэвхжүүлэх вэ?'),
        (Icons.event_outlined,           const Color(0xFF2DB87A), 'Арга хэмжээ зохион байгуулах зөвлөгөө'),
        (Icons.campaign_outlined,        const Color(0xFFE8547A), 'Клубын мэдээ хэрхэн бичих вэ?'),
        (Icons.volunteer_activism_rounded,const Color(0xFFF5A623),'Сайн дурын цаг бүртгэх заавар'),
      ].map((item) => GestureDetector(
        onTap: () => _send(item.$3),
        child: Container(
          width: double.infinity, margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border.withOpacity(0.3))),
          child: Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(color: item.$2.withOpacity(0.15), borderRadius: BorderRadius.circular(11)),
              child: Icon(item.$1, color: item.$2, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Text(item.$3, style: TextStyle(fontSize: 13, color: c.textPrimary, fontWeight: FontWeight.w500))),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: c.textMuted),
          ]),
        ),
      )),
    ]),
  );

  Widget _buildBubble(String text, bool isMe, ThemeColors c) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) ...[
          Container(width: 30, height: 30,
            decoration: BoxDecoration(gradient: c.accentGradient, shape: BoxShape.circle),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16)),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isMe ? c.accentGradient : null,
              color: isMe ? null : c.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4), bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Text(text, style: TextStyle(fontSize: 14, height: 1.5, color: isMe ? Colors.white : c.textPrimary)),
          ),
        ),
      ],
    ),
  );

  Widget _buildTyping(ThemeColors c) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Container(width: 30, height: 30,
        decoration: BoxDecoration(gradient: c.accentGradient, shape: BoxShape.circle),
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: c.surface, borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18), topRight: Radius.circular(18),
          bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18))),
        child: Row(mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) => _DotPulse(delay: i * 180, color: c.primary))),
      ),
    ]),
  );

  Widget _buildInput(ThemeColors c, BuildContext context) => Container(
    padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: MediaQuery.of(context).viewInsets.bottom + 14),
    decoration: BoxDecoration(color: c.bgCard, border: Border(top: BorderSide(color: c.border.withOpacity(0.2)))),
    child: Row(children: [
      Expanded(
        child: Container(
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.border.withOpacity(0.3))),
          child: TextField(
            controller: _msgCtrl, style: TextStyle(fontSize: 14, color: c.textPrimary),
            maxLines: null, textInputAction: TextInputAction.send, onSubmitted: (_) => _send(),
            decoration: InputDecoration(hintText: 'Асуулт бичнэ үү...',
              hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
              border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
          ),
        ),
      ),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: () => _send(),
        child: Container(width: 44, height: 44,
          decoration: BoxDecoration(gradient: c.accentGradient, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: c.primary.withOpacity(0.3), blurRadius: 10)]),
          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20)),
      ),
    ]),
  );
}

// ──────────────────────────────────────────────────────────────
// DM TAB — хэрэглэгч хоорондын мессеж
// ──────────────────────────────────────────────────────────────
class _AdminDmTab extends StatefulWidget {
  const _AdminDmTab();
  @override
  State<_AdminDmTab> createState() => _AdminDmTabState();
}

class _AdminDmTabState extends State<_AdminDmTab> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _convs = [];
  bool _loading = true, _searching = false, _showSearch = false;

  @override
  void initState() { super.initState(); _loadConvs(); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadConvs() async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) return;
      final myConvIds = await supabase.from('conversation_members').select('conversation_id').eq('user_id', uid);
      final ids = (myConvIds as List).map((e) => e['conversation_id'] as String).toList();
      final result = <Map<String, dynamic>>[];
      final colors = [const Color(0xFF4F8EF7), const Color(0xFFE8547A), const Color(0xFF2DB87A), const Color(0xFF7C5CBF)];
      for (final convId in ids) {
        final conv = await supabase.from('conversations').select().eq('id', convId).eq('type', 'direct').maybeSingle();
        if (conv == null) continue;
        final lastMsg = await supabase.from('messages').select('content, created_at')
            .eq('conversation_id', convId).order('created_at', ascending: false).limit(1).maybeSingle();
        final other = await supabase.from('conversation_members').select('user_id').eq('conversation_id', convId).neq('user_id', uid).maybeSingle();
        if (other == null) continue;
        final userInfo = await supabase.from('users').select('full_name, avatar_url').eq('id', other['user_id'] as String).single();
        final name = userInfo['full_name'] as String? ?? 'Хэрэглэгч';
        result.add({
          'id': convId, 'name': name,
          'initials': name.isNotEmpty ? name[0].toUpperCase() : '?',
          'color': colors[result.length % colors.length],
          'lastMsg': lastMsg?['content'] ?? '',
          'lastTime': lastMsg?['created_at'] ?? conv['created_at'],
          'otherUserId': other['user_id'],
          'avatarUrl': userInfo['avatar_url'],
        });
      }
      result.sort((a, b) => (b['lastTime'] as String? ?? '').compareTo(a['lastTime'] as String? ?? ''));
      if (mounted) setState(() { _convs = result; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _searchUsers(String q) async {
    if (q.trim().length < 2) { setState(() { _searchResults = []; _searching = false; }); return; }
    setState(() => _searching = true);
    final uid = supabase.auth.currentUser?.id;
    final res = await supabase.from('users').select('id, full_name, student_code, role')
        .or('full_name.ilike.%$q%,student_code.ilike.%$q%').neq('id', uid ?? '').limit(15);
    if (mounted) setState(() { _searchResults = List<Map<String, dynamic>>.from(res); _searching = false; });
  }

  Future<void> _openOrCreateDm(String otherId, String otherName) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    final myConvs = await supabase.from('conversation_members').select('conversation_id').eq('user_id', uid);
    String? convId;
    for (final mc in (myConvs as List)) {
      final cid  = mc['conversation_id'] as String;
      final conv = await supabase.from('conversations').select().eq('id', cid).eq('type', 'direct').maybeSingle();
      if (conv == null) continue;
      final other = await supabase.from('conversation_members').select().eq('conversation_id', cid).eq('user_id', otherId).maybeSingle();
      if (other != null) { convId = cid; break; }
    }
    if (convId == null) {
      final nc = await supabase.from('conversations').insert({'type': 'direct'}).select().single();
      convId = nc['id'] as String;
      await supabase.from('conversation_members').insert([
        {'conversation_id': convId, 'user_id': uid},
        {'conversation_id': convId, 'user_id': otherId},
      ]);
    }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(value: context.read<ThemeProvider>(),
        child: _ChatDetailScreen(convId: convId!, name: otherName,
          initials: otherName.isNotEmpty ? otherName[0].toUpperCase() : '?', isGroup: false)),
    )).then((_) { _searchCtrl.clear(); setState(() { _searchResults = []; _showSearch = false; }); _loadConvs(); });
  }

  String _timeAgo(String? t) {
    if (t == null) return '';
    final dt = DateTime.tryParse(t)?.toLocal(); if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'Одоо';
    if (d.inMinutes < 60) return '${d.inMinutes}м';
    if (d.inHours < 24) return '${d.inHours}ц';
    return '${d.inDays}өд';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          Expanded(
            child: _showSearch
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.primary.withOpacity(0.5))),
                    child: Row(children: [
                      Icon(Icons.search_rounded, color: c.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(
                        controller: _searchCtrl, autofocus: true,
                        style: TextStyle(color: c.textPrimary, fontSize: 14),
                        onChanged: _searchUsers,
                        decoration: InputDecoration(hintText: 'Нэр, код хайх...',
                          hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
                          border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                      )),
                      if (_searching) SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: c.primary, strokeWidth: 2)),
                    ]))
                : Text('Мессеж', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() { _showSearch = !_showSearch; if (!_showSearch) { _searchCtrl.clear(); _searchResults = []; } }),
            child: Container(width: 38, height: 38,
              decoration: BoxDecoration(
                color: _showSearch ? c.primary.withOpacity(0.15) : c.surface, shape: BoxShape.circle,
                border: Border.all(color: _showSearch ? c.primary.withOpacity(0.5) : c.border.withOpacity(0.3))),
              child: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded,
                color: _showSearch ? c.primary : c.textMuted, size: 18)),
          ),
        ]),
      ),
      if (_showSearch && _searchResults.isNotEmpty)
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: c.bgCard, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))]),
          child: ListView.builder(
            shrinkWrap: true, padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: _searchResults.length,
            itemBuilder: (_, i) {
              final u = _searchResults[i];
              final name = u['full_name'] as String? ?? 'Хэрэглэгч';
              final colors = [const Color(0xFF4F8EF7), const Color(0xFFE8547A), const Color(0xFF2DB87A), const Color(0xFF7C5CBF)];
              return GestureDetector(
                onTap: () => _openOrCreateDm(u['id'] as String, name),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: Row(children: [
                    Container(width: 42, height: 42, decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle),
                      child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(u['student_code'] as String? ?? '', style: TextStyle(color: c.textMuted, fontSize: 12)),
                    ])),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: c.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text('Мессеж', style: TextStyle(color: c.primary, fontSize: 11, fontWeight: FontWeight.w600))),
                  ]),
                ),
              );
            },
          ),
        ),
      Expanded(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: c.primary, strokeWidth: 2))
            : _convs.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.chat_bubble_outline, color: c.textMuted, size: 44),
                    const SizedBox(height: 12),
                    Text('Мессеж байхгүй байна', style: TextStyle(color: c.textMuted)),
                    const SizedBox(height: 6),
                    Text('Дээрх хайлтаар хэрэглэгч хайгаарай', style: TextStyle(color: c.textMuted, fontSize: 12)),
                  ]))
                : ListView.builder(
                    itemCount: _convs.length,
                    itemBuilder: (_, i) {
                      final conv = _convs[i];
                      final color = conv['color'] as Color;
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(value: context.read<ThemeProvider>(),
                            child: _ChatDetailScreen(convId: conv['id'] as String, name: conv['name'] as String,
                              initials: conv['initials'] as String, isGroup: false)),
                        )).then((_) => _loadConvs()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border.withOpacity(0.08)))),
                          child: Row(children: [
                            Container(width: 52, height: 52, decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              child: Center(child: Text(conv['initials'] as String,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(conv['name'] as String,
                                  style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w600))),
                                Text(_timeAgo(conv['lastTime'] as String?),
                                  style: TextStyle(color: c.textMuted, fontSize: 11)),
                              ]),
                              const SizedBox(height: 3),
                              Text(conv['lastMsg'] as String? ?? '',
                                style: TextStyle(color: c.textMuted, fontSize: 13),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            ])),
                          ]),
                        ),
                      );
                    },
                  ),
      ),
    ]);
  }
}

// ──────────────────────────────────────────────────────────────
// GROUP CHAT TAB — клубын группын чат + гишүүд урих
// ──────────────────────────────────────────────────────────────
class _AdminGroupTab extends StatefulWidget {
  final String clubId, clubName;
  const _AdminGroupTab({required this.clubId, required this.clubName});
  @override
  State<_AdminGroupTab> createState() => _AdminGroupTabState();
}

class _AdminGroupTabState extends State<_AdminGroupTab> {
  List<Map<String, dynamic>> _groups = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final uid = supabase.auth.currentUser?.id;
      // Клубийн групп чатуудыг ачаална
      final convs = await supabase.from('conversations')
          .select('id, club_id, name, created_at')
          .eq('type', 'group').eq('club_id', widget.clubId);
      final result = <Map<String, dynamic>>[];
      for (final conv in (convs as List)) {
        final lastMsg = await supabase.from('messages').select('content, created_at, sender_id')
            .eq('conversation_id', conv['id'] as String)
            .order('created_at', ascending: false).limit(1).maybeSingle();
        final memberCount = await supabase.from('conversation_members')
            .select('id').eq('conversation_id', conv['id'] as String);
        result.add({
          'id': conv['id'],
          'name': conv['name'] ?? widget.clubName,
          'lastMsg': lastMsg?['content'] ?? '',
          'lastTime': lastMsg?['created_at'] ?? conv['created_at'],
          'memberCount': (memberCount as List).length,
        });
      }
      // Групп байхгүй бол автоматаар үүсгэнэ
      if (result.isEmpty) await _ensureGroupConv();
      if (mounted) setState(() { _groups = result; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _ensureGroupConv() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    final existing = await supabase.from('conversations')
        .select('id').eq('club_id', widget.clubId).eq('type', 'group').maybeSingle();
    if (existing != null) return;
    final newConv = await supabase.from('conversations').insert({
      'type': 'group', 'club_id': widget.clubId, 'name': widget.clubName,
    }).select().single();
    final convId = newConv['id'] as String;
    // Бүх гишүүдийг нэмнэ
    final members = await supabase.from('club_memberships')
        .select('user_id').eq('club_id', widget.clubId).eq('status', 'approved');
    final inserts = (members as List).map((m) => {'conversation_id': convId, 'user_id': m['user_id']}).toList();
    if (uid != null && !inserts.any((i) => i['user_id'] == uid)) inserts.add({'conversation_id': convId, 'user_id': uid});
    if (inserts.isNotEmpty) await supabase.from('conversation_members').upsert(inserts);
    await _load();
  }

  void _showInviteSheet(String convId) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(value: context.read<ThemeProvider>(),
        child: _InviteMembersSheet(clubId: widget.clubId, convId: convId, onDone: _load)),
    );
  }

  String _timeAgo(String? t) {
    if (t == null) return '';
    final dt = DateTime.tryParse(t)?.toLocal(); if (dt == null) return '';
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'Одоо';
    if (d.inMinutes < 60) return '${d.inMinutes}м';
    if (d.inHours < 24) return '${d.inHours}ц';
    return '${d.inDays}өд';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    if (_loading) return Center(child: CircularProgressIndicator(color: c.primary, strokeWidth: 2));
    if (_groups.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.group_outlined, color: c.textMuted, size: 48),
      const SizedBox(height: 12),
      Text('Групп чат байхгүй байна', style: TextStyle(color: c.textMuted)),
      const SizedBox(height: 12),
      ElevatedButton.icon(onPressed: _ensureGroupConv,
        icon: const Icon(Icons.add), label: const Text('Групп үүсгэх')),
    ]));

    return Column(children: [
      // Шинэ групп үүсгэх товч
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Групп чатууд', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)),
          TextButton.icon(
            onPressed: _ensureGroupConv,
            icon: Icon(Icons.add, size: 16, color: c.primary),
            label: Text('Шинэ групп', style: TextStyle(color: c.primary, fontSize: 13)),
          ),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: _groups.length,
          itemBuilder: (_, i) {
            final g = _groups[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(value: context.read<ThemeProvider>(),
                    child: _GroupChatScreen(
                      convId: g['id'] as String,
                      name: g['name'] as String,
                      clubId: widget.clubId,
                      onInvite: () => _showInviteSheet(g['id'] as String),
                    )),
                )).then((_) => _load()),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(width: 52, height: 52,
                      decoration: BoxDecoration(gradient: c.accentGradient, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.group_rounded, color: Colors.white, size: 26)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(g['name'] as String, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: c.textPrimary)),
                      const SizedBox(height: 3),
                      Row(children: [
                        Icon(Icons.people_outline, size: 12, color: c.textMuted),
                        const SizedBox(width: 4),
                        Text('${g['memberCount']} гишүүн', style: TextStyle(fontSize: 12, color: c.textMuted)),
                        if ((g['lastMsg'] as String).isNotEmpty) ...[
                          Text('  ·  ', style: TextStyle(color: c.textMuted)),
                          Expanded(child: Text(g['lastMsg'] as String,
                            style: TextStyle(fontSize: 12, color: c.textMuted),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ]),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(_timeAgo(g['lastTime'] as String?), style: TextStyle(fontSize: 11, color: c.textMuted)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _showInviteSheet(g['id'] as String),
                        child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: c.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.person_add_alt_1_outlined, size: 13, color: c.primary),
                            const SizedBox(width: 4),
                            Text('Урих', style: TextStyle(fontSize: 11, color: c.primary, fontWeight: FontWeight.w600)),
                          ])),
                      ),
                    ]),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

// ──────────────────────────────────────────────────────────────
// GROUP CHAT SCREEN — дотоод чат дэлгэц
// ──────────────────────────────────────────────────────────────
class _GroupChatScreen extends StatefulWidget {
  final String convId, name, clubId;
  final VoidCallback onInvite;
  const _GroupChatScreen({required this.convId, required this.name, required this.clubId, required this.onInvite});
  @override
  State<_GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<_GroupChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  Map<String, String> _userNames = {};
  bool _loading = true;
  RealtimeChannel? _channel;
  String? _myUid;

  @override
  void initState() {
    super.initState();
    _myUid = supabase.auth.currentUser?.id;
    _loadMessages();
    _subscribeRealtime();
  }

  @override
  void dispose() { _ctrl.dispose(); _scrollCtrl.dispose(); _channel?.unsubscribe(); super.dispose(); }

  Future<void> _loadMessages() async {
    final msgs = await supabase.from('messages').select('*, sender:sender_id(full_name)')
        .eq('conversation_id', widget.convId).order('created_at', ascending: true).limit(100);
    final names = <String, String>{};
    for (final m in (msgs as List)) {
      final sid = m['sender_id'] as String;
      names[sid] = (m['sender'] as Map?)?['full_name'] as String? ?? 'Хэрэглэгч';
    }
    if (mounted) setState(() { _messages = List<Map<String, dynamic>>.from(msgs); _userNames = names; _loading = false; });
    _scrollToBottom();
  }

  void _subscribeRealtime() {
    _channel = supabase.channel('group_${widget.convId}')
        .onPostgresChanges(event: PostgresChangeEvent.insert, schema: 'public', table: 'messages',
          callback: (payload) async {
            final nm = payload.newRecord;
            if (nm['conversation_id'] != widget.convId) return;
            if (!_userNames.containsKey(nm['sender_id'])) {
              final u = await supabase.from('users').select('full_name').eq('id', nm['sender_id']).single();
              _userNames[nm['sender_id'] as String] = u['full_name'] as String? ?? 'Хэрэглэгч';
            }
            if (mounted) { setState(() => _messages.add(nm)); _scrollToBottom(); }
          }).subscribe();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _myUid == null) return;
    _ctrl.clear();
    await supabase.from('messages').insert({'conversation_id': widget.convId, 'sender_id': _myUid!, 'content': text});
  }

  void _scrollToBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  });

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Scaffold(
      backgroundColor: c.bgDark,
      appBar: AppBar(
        backgroundColor: c.bgDark.withOpacity(0.97), elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_rounded, color: c.textPrimary, size: 18), onPressed: () => Navigator.pop(context)),
        title: Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(gradient: c.accentGradient, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.group_rounded, color: Colors.white, size: 18)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.name, style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            Text('Группын чат', style: TextStyle(color: c.textMuted, fontSize: 11)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_alt_1_outlined, color: c.primary),
            tooltip: 'Гишүүн урих',
            onPressed: widget.onInvite,
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: c.primary, strokeWidth: 2))
              : _messages.isEmpty
                  ? Center(child: Text('Мессеж байхгүй байна', style: TextStyle(color: c.textMuted)))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _buildBubble(_messages[i], c),
                    ),
        ),
        _buildInput(c, context),
      ]),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, ThemeColors c) {
    final isMe = msg['sender_id'] == _myUid;
    final senderName = _userNames[msg['sender_id']] ?? 'Хэрэглэгч';
    final time = _fmtTime(msg['created_at'] as String?);
    final content = msg['content'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(width: 28, height: 28,
              decoration: BoxDecoration(color: c.primary.withOpacity(0.8), shape: BoxShape.circle),
              child: Center(child: Text(senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))),
            const SizedBox(width: 6),
          ],
          Flexible(child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe) Padding(padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(senderName, style: TextStyle(color: c.textMuted, fontSize: 11))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  gradient: isMe ? c.accentGradient : null,
                  color: isMe ? null : c.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4), bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                ),
                child: Text(content, style: TextStyle(fontSize: 14, height: 1.4, color: isMe ? Colors.white : c.textPrimary)),
              ),
              const SizedBox(height: 2),
              Text(time, style: TextStyle(color: c.textMuted, fontSize: 10)),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildInput(ThemeColors c, BuildContext ctx) => Container(
    padding: EdgeInsets.only(left: 12, right: 12, top: 10, bottom: MediaQuery.of(ctx).viewInsets.bottom + 14),
    decoration: BoxDecoration(color: c.bgDark, border: Border(top: BorderSide(color: c.border.withOpacity(0.15)))),
    child: Row(children: [
      Expanded(
        child: Container(
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.border.withOpacity(0.3))),
          child: TextField(
            controller: _ctrl, style: TextStyle(color: c.textPrimary, fontSize: 14),
            onSubmitted: (_) => _send(), maxLines: null,
            decoration: InputDecoration(hintText: 'Мессеж бичих...',
              hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
              border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          ),
        ),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: _send,
        child: Container(width: 46, height: 46,
          decoration: BoxDecoration(gradient: c.accentGradient, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: c.primary.withOpacity(0.3), blurRadius: 10)]),
          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20)),
      ),
    ]),
  );

  String _fmtTime(String? t) {
    if (t == null) return '';
    final dt = DateTime.tryParse(t)?.toLocal(); if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ──────────────────────────────────────────────────────────────
// INVITE MEMBERS SHEET
// ──────────────────────────────────────────────────────────────
class _InviteMembersSheet extends StatefulWidget {
  final String clubId, convId;
  final VoidCallback onDone;
  const _InviteMembersSheet({required this.clubId, required this.convId, required this.onDone});
  @override
  State<_InviteMembersSheet> createState() => _InviteMembersSheetState();
}

class _InviteMembersSheetState extends State<_InviteMembersSheet> {
  List<Map<String, dynamic>> _members = [];
  Set<String> _alreadyIn = {};
  Set<String> _selected  = {};
  bool _loading = true, _saving = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    // Клубийн бүх гишүүд
    final members = await supabase.from('club_memberships')
        .select('user_id, users(full_name, student_code)').eq('club_id', widget.clubId).eq('status', 'approved');
    // Аль хэдийн чатанд байгаа гишүүд
    final inChat = await supabase.from('conversation_members').select('user_id').eq('conversation_id', widget.convId);
    if (mounted) setState(() {
      _members = List<Map<String, dynamic>>.from(members);
      _alreadyIn = Set<String>.from((inChat as List).map((m) => m['user_id'] as String));
      _loading = false;
    });
  }

  Future<void> _invite() async {
    if (_selected.isEmpty) return;
    final c = context.read<ThemeProvider>().colors;
    setState(() => _saving = true);
    final inserts = _selected.map((uid) => {'conversation_id': widget.convId, 'user_id': uid}).toList();
    await supabase.from('conversation_members').upsert(inserts);
    widget.onDone();
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_selected.length} гишүүн урагдлаа'), backgroundColor: c.teal));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Container(
      decoration: BoxDecoration(color: c.bgCard, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)))),
        Text('Гишүүд урих', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)),
        const SizedBox(height: 12),
        if (_loading) const CircularProgressIndicator()
        else Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _members.length,
            itemBuilder: (_, i) {
              final m    = _members[i];
              final u    = (m['users'] as Map<String, dynamic>?) ?? {};
              final uid  = m['user_id'] as String;
              final name = u['full_name'] as String? ?? 'Нэргүй';
              final code = u['student_code'] as String? ?? '';
              final done = _alreadyIn.contains(uid);
              return CheckboxListTile(
                value: done || _selected.contains(uid),
                onChanged: done ? null : (v) => setState(() { if (v!) _selected.add(uid); else _selected.remove(uid); }),
                title: Text(name, style: TextStyle(color: done ? c.textMuted : c.textPrimary, fontSize: 14)),
                subtitle: code.isNotEmpty ? Text(code, style: TextStyle(color: c.textMuted, fontSize: 12)) : null,
                secondary: CircleAvatar(backgroundColor: c.primaryLight,
                  child: Text(name.isNotEmpty ? name[0] : '?', style: TextStyle(color: c.primary))),
                activeColor: c.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _saving
            ? const CircularProgressIndicator()
            : SizedBox(width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selected.isEmpty ? null : _invite,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: Text('${_selected.length} гишүүн урих'))),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// DM CHAT DETAIL SCREEN (хуваалцах)
// ──────────────────────────────────────────────────────────────
class _ChatDetailScreen extends StatefulWidget {
  final String convId, name, initials;
  final bool isGroup;
  const _ChatDetailScreen({required this.convId, required this.name, required this.initials, required this.isGroup});
  @override
  State<_ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<_ChatDetailScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  Map<String, String> _userNames = {};
  bool _loading = true;
  RealtimeChannel? _channel;
  String? _myUid;

  @override
  void initState() { super.initState(); _myUid = supabase.auth.currentUser?.id; _loadMessages(); _subscribeRealtime(); }
  @override
  void dispose() { _ctrl.dispose(); _scrollCtrl.dispose(); _channel?.unsubscribe(); super.dispose(); }

  Future<void> _loadMessages() async {
    final msgs = await supabase.from('messages').select('*, sender:sender_id(full_name)')
        .eq('conversation_id', widget.convId).order('created_at', ascending: true).limit(100);
    final names = <String, String>{};
    for (final m in (msgs as List)) names[m['sender_id'] as String] = (m['sender'] as Map?)?['full_name'] as String? ?? 'Хэрэглэгч';
    if (mounted) setState(() { _messages = List<Map<String, dynamic>>.from(msgs); _userNames = names; _loading = false; });
    _scrollToBottom();
  }

  void _subscribeRealtime() {
    _channel = supabase.channel('dm_${widget.convId}')
        .onPostgresChanges(event: PostgresChangeEvent.insert, schema: 'public', table: 'messages',
          callback: (payload) async {
            final nm = payload.newRecord;
            if (nm['conversation_id'] != widget.convId) return;
            if (!_userNames.containsKey(nm['sender_id'])) {
              final u = await supabase.from('users').select('full_name').eq('id', nm['sender_id']).single();
              _userNames[nm['sender_id'] as String] = u['full_name'] as String? ?? 'Хэрэглэгч';
            }
            if (mounted) { setState(() => _messages.add(nm)); _scrollToBottom(); }
          }).subscribe();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _myUid == null) return;
    _ctrl.clear();
    await supabase.from('messages').insert({'conversation_id': widget.convId, 'sender_id': _myUid!, 'content': text});
  }

  void _scrollToBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  });

  String _fmtTime(String? t) {
    if (t == null) return '';
    final dt = DateTime.tryParse(t)?.toLocal(); if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Scaffold(
      backgroundColor: c.bgDark,
      appBar: AppBar(
        backgroundColor: c.bgDark.withOpacity(0.97), elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_rounded, color: c.textPrimary, size: 18), onPressed: () => Navigator.pop(context)),
        title: Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
            child: Center(child: Text(widget.initials, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 10),
          Text(widget.name, style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: c.primary, strokeWidth: 2))
              : _messages.isEmpty
                  ? Center(child: Text('Мессеж байхгүй байна', style: TextStyle(color: c.textMuted)))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final msg = _messages[i];
                        final isMe = msg['sender_id'] == _myUid;
                        final content = msg['content'] as String? ?? '';
                        final time = _fmtTime(msg['created_at'] as String?);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isMe) ...[
                                Container(width: 28, height: 28,
                                  decoration: BoxDecoration(color: c.primary.withOpacity(0.8), shape: BoxShape.circle),
                                  child: Center(child: Text(widget.initials,
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))),
                                const SizedBox(width: 6),
                              ],
                              Flexible(child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                    decoration: BoxDecoration(
                                      gradient: isMe ? c.accentGradient : null, color: isMe ? null : c.surface,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                                        bottomLeft: Radius.circular(isMe ? 18 : 4), bottomRight: Radius.circular(isMe ? 4 : 18),
                                      ),
                                    ),
                                    child: Text(content, style: TextStyle(fontSize: 14, height: 1.4, color: isMe ? Colors.white : c.textPrimary)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(time, style: TextStyle(color: c.textMuted, fontSize: 10)),
                                ],
                              )),
                            ],
                          ),
                        );
                      },
                    ),
        ),
        Container(
          padding: EdgeInsets.only(left: 12, right: 12, top: 10, bottom: MediaQuery.of(context).viewInsets.bottom + 14),
          decoration: BoxDecoration(color: c.bgDark, border: Border(top: BorderSide(color: c.border.withOpacity(0.15)))),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: c.border.withOpacity(0.3))),
                child: TextField(
                  controller: _ctrl, style: TextStyle(color: c.textPrimary, fontSize: 14),
                  onSubmitted: (_) => _send(), maxLines: null,
                  decoration: InputDecoration(hintText: 'Мессеж бичих...',
                    hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
                    border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(width: 46, height: 46,
                decoration: BoxDecoration(gradient: c.accentGradient, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: c.primary.withOpacity(0.3), blurRadius: 10)]),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20)),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// DASHBOARD TAB
// ══════════════════════════════════════════════════════════════
class _DashboardTab extends StatefulWidget {
  final String clubId;
  const _DashboardTab({required this.clubId});
  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  Map<String, dynamic>? _club;
  int _memberCount = 0, _pendingCount = 0;
  double _totalHours = 0, _avgRating = 0;
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final club    = await ClubService().getClub(widget.clubId);
    final members = await supabase.from('club_memberships').select('id').eq('club_id', widget.clubId).eq('status', 'approved');
    final pending = await supabase.from('join_requests').select('id').eq('club_id', widget.clubId).eq('status', 'pending');
    final hours   = await supabase.from('volunteer_hours').select('hours').eq('club_id', widget.clubId);
    final reviewRows = await supabase.from('reviews')
        .select('*, users!reviews_user_id_fkey(full_name)')
        .eq('club_id', widget.clubId)
        .order('created_at', ascending: false);
    final visibleReviews = (reviewRows as List)
        .where((r) => r['is_visible'] != false)
        .toList();
    if (mounted) setState(() {
      _club = club;
      _memberCount = (members as List).length;
      _pendingCount = (pending as List).length;
      _totalHours = (hours as List).fold(0.0, (s, e) => s + (e['hours'] as num).toDouble());
      _avgRating  = visibleReviews.isEmpty
          ? 0
          : visibleReviews.fold<double>(0.0, (s, e) => s + (e['rating'] as num).toDouble()) / visibleReviews.length;
      _reviews = List<Map<String, dynamic>>.from(reviewRows);
      _loading = false;
    });
  }

  void _openReviewsPage() {
    final tp = context.read<ThemeProvider>();
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: tp,
        child: _AdminReviewsPage(clubId: widget.clubId),
      ),
    )).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    if (_loading) return const LoadingView();
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_club != null) _buildClubHeaderCard(c),
          const SizedBox(height: 16),
          GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.6,
            children: [
              _statCard(c, 'Гишүүдийн тоо', '$_memberCount', Icons.people_rounded, c.primary),
              _statCard(c, 'Хүлээгдэж буй', '$_pendingCount', Icons.pending_rounded, const Color(0xFFFFBE45)),
              _statCard(c, 'Нийт цаг', _totalHours.toStringAsFixed(1), Icons.schedule_rounded, c.teal),
              _statCard(c, 'Дундаж үнэлгээ', _avgRating > 0 ? _avgRating.toStringAsFixed(1) : '-', Icons.star_rounded, c.coral),
            ],
          ),
          // FAB-аас үүдэн доороо нэмэлт зай үлдээнэ
          const SizedBox(height: 80),
        ]),
      ),
    );
  }

  /// S-R120 толгой карт — клубын нэр, ангилал, rating, сэтгэгдэл бүгд НЭГ карт дотор.
  Widget _buildClubHeaderCard(ThemeColors c) {
    final visibleCount = _reviews.where((r) => r['is_visible'] != false).length;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: c.headerGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: _openReviewsPage,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.groups_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_club!['name'] ?? '',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 2),
                Text(_club!['category'] ?? '',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                const SizedBox(height: 6),
                // Сэтгэгдэл харах link — нэр, ангилалын ДОР дотор нь
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.rate_review_rounded,
                    size: 13, color: Colors.white.withOpacity(0.85)),
                  const SizedBox(width: 4),
                  Text(visibleCount == 0
                          ? 'Сэтгэгдэл байхгүй'
                          : 'Бүх $visibleCount сэтгэгдлийг харах',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w500)),
                ]),
              ])),
              const SizedBox(width: 8),
              if (_avgRating > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFD66B), size: 16),
                    const SizedBox(width: 4),
                    Text(_avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                ),
            ]),
          ),
        ),
      ),
    );
  }


  Widget _statCard(ThemeColors c, String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 22), const Spacer(),
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════
// CLUBS TAB
// ══════════════════════════════════════════════════════════════
class _ClubsTab extends StatefulWidget {
  final String clubId, clubName;
  const _ClubsTab({required this.clubId, required this.clubName});
  @override
  State<_ClubsTab> createState() => _ClubsTabState();
}

class _ClubsTabState extends State<_ClubsTab> {
  final _adminService = AdminService();
  final _reqService = JoinRequestService();
  List<Map<String, dynamic>> _members = [];
  int _pendingRequests = 0;
  Map<String, dynamic>? _club;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ClubService().getClub(widget.clubId),
      _adminService.getClubMembers(widget.clubId),
      _reqService.getClubRequests(widget.clubId),
    ]);
    if (mounted) {
      setState(() {
        _club    = results[0] as Map<String, dynamic>?;
        _members = results[1] as List<Map<String, dynamic>>;
        _pendingRequests = (results[2] as List).length;
        _loading = false;
      });
    }
  }

  String _initial(dynamic name) { final s = (name ?? '').toString(); return s.isNotEmpty ? s[0] : '?'; }

  void _openClubInfoEdit() {
    final tp = context.read<ThemeProvider>();
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: tp,
        child: _ClubInfoEditPage(clubId: widget.clubId, club: _club ?? {}),
      ),
    )).then((_) => _load());
  }

  void _openRequests() {
    final tp = context.read<ThemeProvider>();
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: tp,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Клубын хүсэлтүүд'),
            actions: [_ThemeSwitchButton()],
          ),
          body: _RequestsTab(clubId: widget.clubId),
        ),
      ),
    )).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    if (_loading) return const LoadingView();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // 1) Long card — Клубын мэдээлэл засах
          _LongActionCard(
            icon: Icons.edit_note_rounded,
            iconColor: c.primary,
            title: 'Клубын мэдээлэл засах',
            subtitle: _club?['name'] != null
                ? '${_club!['name']} — нэр, тайлбар, холбоо барих'
                : 'Нэр, тайлбар, холбоо барих засах',
            onTap: _openClubInfoEdit,
          ),
          const SizedBox(height: 10),
          // 2) Long card — Клубын хүсэлтүүд
          _LongActionCard(
            icon: Icons.inbox_rounded,
            iconColor: const Color(0xFFFFBE45),
            title: 'Клубын хүсэлтүүд',
            subtitle: _pendingRequests == 0
                ? 'Хүлээгдэж буй хүсэлт байхгүй'
                : '$_pendingRequests хүлээгдэж буй хүсэлт',
            badge: _pendingRequests > 0 ? '$_pendingRequests' : null,
            onTap: _openRequests,
          ),
          const SizedBox(height: 10),
          // 3) Long card — Санал асуулга
          _LongActionCard(
            icon: Icons.poll_rounded,
            iconColor: const Color(0xFFB06BFF),
            title: 'Санал асуулга',
            subtitle: 'Шинэ poll үүсгэх / удирдах',
            onTap: () {
              final tp = context.read<ThemeProvider>();
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: tp,
                  child: _AdminPollsPage(clubId: widget.clubId, clubName: _club?['name'] ?? ''),
                ),
              ));
            },
          ),
          const SizedBox(height: 24),
          // 3) Гишүүд (өмнөх шигээ үлдэв)
          Text('Гишүүд (${_members.length})',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: c.textPrimary)),
          const SizedBox(height: 10),
          if (_members.isEmpty)
            const EmptyState(message: 'Гишүүн байхгүй', icon: Icons.people_outline)
          else
            ..._members.map((m) {
              final u = m['users'] as Map<String, dynamic>? ?? {};
              return Card(margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: c.primaryLight,
                    child: Text(_initial(u['full_name']),
                      style: TextStyle(color: c.primary, fontWeight: FontWeight.w600))),
                  title: Text(u['full_name'] ?? 'Нэргүй'),
                  subtitle: Text(u['student_code'] ?? ''),
                  trailing: IconButton(
                    icon: Icon(Icons.person_remove_outlined, color: c.coral),
                    tooltip: 'Хасах',
                    onPressed: () async {
                      await _adminService.removeMember(m['user_id'], widget.clubId);
                      _load();
                    }),
                ));
            }),
        ],
      ),
    );
  }
}

// ── Long horizontal action card — Клуб tab дээрх 2 entry-нд ─────
class _LongActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;
  const _LongActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: c.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle,
                style: TextStyle(fontSize: 12, color: c.textMuted),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: c.coral.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
              child: Text(badge!,
                style: TextStyle(fontSize: 11, color: c.coral, fontWeight: FontWeight.w700)),
            ),
          ],
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded, color: c.textMuted, size: 14),
        ]),
      ),
    );
  }
}

// ── Клубын мэдээлэл засах page (бие даасан дэлгэц) ─────────────
class _ClubInfoEditPage extends StatefulWidget {
  final String clubId;
  final Map<String, dynamic> club;
  const _ClubInfoEditPage({required this.clubId, required this.club});
  @override
  State<_ClubInfoEditPage> createState() => _ClubInfoEditPageState();
}

class _ClubInfoEditPageState extends State<_ClubInfoEditPage> {
  late TextEditingController _nameCtrl, _descCtrl, _emailCtrl, _phoneCtrl, _instrCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.club['name']             ?? '');
    _descCtrl  = TextEditingController(text: widget.club['description']      ?? '');
    _emailCtrl = TextEditingController(text: widget.club['email']            ?? '');
    _phoneCtrl = TextEditingController(text: widget.club['phone']            ?? '');
    _instrCtrl = TextEditingController(text: widget.club['join_instruction'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _instrCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final c = context.read<ThemeProvider>().colors;
    setState(() => _saving = true);
    try {
      await ClubService().updateClub(widget.clubId, {
        'name':             _nameCtrl.text.trim(),
        'description':      _descCtrl.text.trim(),
        'email':            _emailCtrl.text.trim(),
        'phone':            _phoneCtrl.text.trim(),
        'join_instruction': _instrCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Амжилттай хадгалагдлаа'), backgroundColor: c.teal));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Алдаа: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Клубын мэдээлэл засах'),
        actions: [_ThemeSwitchButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppTextField(controller: _nameCtrl, label: 'Клубын нэр'),
          const SizedBox(height: 10),
          AppTextField(controller: _descCtrl, label: 'Тайлбар', maxLines: 3),
          const SizedBox(height: 10),
          AppTextField(controller: _emailCtrl, label: 'И-мэйл', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 10),
          AppTextField(controller: _phoneCtrl, label: 'Утас', keyboardType: TextInputType.phone),
          const SizedBox(height: 10),
          AppTextField(controller: _instrCtrl, label: 'Элсэх заавар', maxLines: 2),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined),
              label: const Text('Хадгалах'))),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// REQUESTS TAB
// ══════════════════════════════════════════════════════════════
class _RequestsTab extends StatefulWidget {
  final String clubId;
  const _RequestsTab({required this.clubId});
  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  final _reqService = JoinRequestService();
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final reqs = await _reqService.getClubRequests(widget.clubId);
    if (mounted) setState(() { _requests = reqs; _loading = false; });
  }
  String _initial(dynamic name) { final s = (name ?? '').toString(); return s.isNotEmpty ? s[0] : '?'; }
  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return _loading ? const LoadingView() : RefreshIndicator(
      onRefresh: _load,
      child: _requests.isEmpty
          ? const EmptyState(message: 'Хүлээгдэж буй хүсэлт байхгүй', icon: Icons.check_circle_outline)
          : ListView.builder(
              padding: const EdgeInsets.all(16), itemCount: _requests.length,
              itemBuilder: (_, i) {
                final r = _requests[i]; final user = r['users'] as Map<String, dynamic>? ?? {};
                return Card(margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        CircleAvatar(radius: 18, backgroundColor: c.primaryLight,
                          child: Text(_initial(user['full_name']), style: TextStyle(color: c.primary, fontWeight: FontWeight.w600, fontSize: 14))),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(user['full_name'] ?? 'Нэргүй', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('${user['student_code'] ?? ''}  ·  ${user['department'] ?? ''}', style: TextStyle(fontSize: 12, color: c.textMuted)),
                        ])),
                      ]),
                      if (r['message'] != null && (r['message'] as String).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(8)),
                          child: Text(r['message'], style: TextStyle(fontSize: 13, color: c.textMuted))),
                      ],
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: OutlinedButton.icon(
                          onPressed: () async { await _reqService.rejectRequest(r['id']); _load(); },
                          icon: const Icon(Icons.close, size: 16), label: const Text('Татгалзах'),
                          style: OutlinedButton.styleFrom(foregroundColor: c.coral, side: BorderSide(color: c.coral)))),
                        const SizedBox(width: 8),
                        Expanded(child: ElevatedButton.icon(
                          onPressed: () async { await _reqService.approveRequest(r['id']); _load(); },
                          icon: const Icon(Icons.check, size: 16), label: const Text('Батлах'),
                          style: ElevatedButton.styleFrom(backgroundColor: c.teal))),
                      ]),
                    ])));
              }));
  }
}

// ══════════════════════════════════════════════════════════════
// CONTENT TAB
// ══════════════════════════════════════════════════════════════
class _ContentTab extends StatefulWidget {
  final String clubId;
  const _ContentTab({required this.clubId});
  @override
  State<_ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends State<_ContentTab> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Column(children: [
      Container(color: c.bgCard,
        child: TabBar(controller: _tabCtrl, labelColor: c.primary, unselectedLabelColor: c.textMuted, indicatorColor: c.primary,
          tabs: const [Tab(icon: Icon(Icons.campaign_outlined, size: 18), text: 'Клубын мэдээ'), Tab(icon: Icon(Icons.event_outlined, size: 18), text: 'Арга хэмжээ')])),
      Expanded(child: TabBarView(controller: _tabCtrl, children: [_AnnouncementsTab(clubId: widget.clubId), _EventsTab(clubId: widget.clubId)])),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
// ANNOUNCEMENTS SUB-TAB
// ══════════════════════════════════════════════════════════════
class _AnnouncementsTab extends StatefulWidget {
  final String clubId;
  const _AnnouncementsTab({required this.clubId});
  @override
  State<_AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<_AnnouncementsTab> {
  List<Map<String, dynamic>> _items = []; bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final res = await supabase.from('announcements').select().eq('club_id', widget.clubId).order('created_at', ascending: false); if (mounted) setState(() { _items = res; _loading = false; }); }
  Future<void> _delete(String id) async { await supabase.from('announcements').delete().eq('id', id); _load(); }
  void _openForm({Map<String, dynamic>? item}) { showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _AnnouncementForm(clubId: widget.clubId, item: item, onSaved: () { Navigator.pop(context); _load(); })); }
  String _fmt(String? iso) { if (iso == null) return ''; final d = DateTime.tryParse(iso); if (d == null) return ''; return '${d.year}.${d.month.toString().padLeft(2,'0')}.${d.day.toString().padLeft(2,'0')}'; }
  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Scaffold(backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _openForm(), icon: const Icon(Icons.add), label: const Text('Мэдээ нэмэх'), backgroundColor: c.primary),
      body: _loading ? const LoadingView() : RefreshIndicator(onRefresh: _load,
        child: _items.isEmpty ? const EmptyState(message: 'Мэдээ/зарлал байхгүй байна', icon: Icons.campaign_outlined)
            : ListView.builder(padding: const EdgeInsets.fromLTRB(16,16,16,80), itemCount: _items.length, itemBuilder: (_, i) {
                final a = _items[i]; final isPublished = a['status'] == 'published';
                return Card(margin: const EdgeInsets.only(bottom: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (a['image_url'] != null) ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: Image.network(a['image_url'], height: 160, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
                  Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: isPublished ? c.teal.withOpacity(0.12) : const Color(0xFFFFBE45).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text(isPublished ? 'Нийтлэгдсэн' : 'Ноорог', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isPublished ? c.teal : const Color(0xFFFFBE45)))),
                      const Spacer(), Text(_fmt(a['created_at']), style: TextStyle(fontSize: 11, color: c.textMuted)),
                    ]),
                    const SizedBox(height: 8),
                    Text(a['title'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: c.textPrimary)),
                    const SizedBox(height: 4),
                    Text(a['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: c.textMuted)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(onPressed: () => _openForm(item: a), icon: const Icon(Icons.edit_outlined, size: 15), label: const Text('Засах'))),
                      const SizedBox(width: 8),
                      Expanded(child: OutlinedButton.icon(
                        onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Устгах уу?'), content: const Text('Энэ мэдээг устгах уу?'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Цуцлах')), ElevatedButton(onPressed: () { Navigator.pop(context); _delete(a['id']); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Устгах'))])),
                        icon: const Icon(Icons.delete_outline, size: 15), label: const Text('Устгах'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)))),
                    ]),
                  ])),
                ]));
              })));
  }
}

// ══════════════════════════════════════════════════════════════
// EVENTS SUB-TAB
// ══════════════════════════════════════════════════════════════
class _EventsTab extends StatefulWidget {
  final String clubId;
  const _EventsTab({required this.clubId});
  @override
  State<_EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<_EventsTab> {
  List<Map<String, dynamic>> _events = []; bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final res = await supabase.from('events').select().eq('club_id', widget.clubId).order('event_date', ascending: true); if (mounted) setState(() { _events = res; _loading = false; }); }
  Future<void> _delete(String id) async { await supabase.from('events').delete().eq('id', id); _load(); }
  void _openForm({Map<String, dynamic>? item}) { showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => ChangeNotifierProvider.value(value: context.read<ThemeProvider>(), child: _EventForm(clubId: widget.clubId, item: item, onSaved: () { Navigator.pop(context); _load(); }))); }
  String _fmt(String? iso) { if (iso == null) return ''; final d = DateTime.tryParse(iso)?.toLocal(); if (d == null) return ''; return '${d.year}.${d.month.toString().padLeft(2,'0')}.${d.day.toString().padLeft(2,'0')}'; }
  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Scaffold(backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _openForm(), icon: const Icon(Icons.add), label: const Text('Арга хэмжээ нэмэх'), backgroundColor: c.teal),
      body: _loading ? const LoadingView() : RefreshIndicator(onRefresh: _load,
        child: _events.isEmpty ? const EmptyState(message: 'Арга хэмжээ байхгүй байна', icon: Icons.event_outlined)
            : ListView.builder(padding: const EdgeInsets.fromLTRB(16,16,16,80), itemCount: _events.length, itemBuilder: (_, i) {
                final e = _events[i]; final dateStr = _fmt(e['event_date']);
                return Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: c.teal.withOpacity(0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: c.teal.withOpacity(0.2))), child: Icon(Icons.event_rounded, color: c.teal, size: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e['title'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: c.textPrimary)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.calendar_today_outlined, size: 12, color: c.teal), const SizedBox(width: 4),
                        Text(dateStr, style: TextStyle(fontSize: 12, color: c.teal, fontWeight: FontWeight.w600)),
                        if ((e['location'] ?? '').isNotEmpty) ...[const SizedBox(width: 8), Icon(Icons.location_on_outlined, size: 12, color: c.textMuted), const SizedBox(width: 2), Expanded(child: Text(e['location'] ?? '', style: TextStyle(fontSize: 12, color: c.textMuted), overflow: TextOverflow.ellipsis))],
                      ]),
                    ])),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: c.teal.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Text('${e['hours'] ?? 0}ц', style: TextStyle(fontSize: 12, color: c.teal, fontWeight: FontWeight.w700))),
                  ]),
                  if ((e['description'] ?? '').isNotEmpty) ...[const SizedBox(height: 8), Text(e['description'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: c.textMuted))],
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(onPressed: () => _openForm(item: e), icon: const Icon(Icons.edit_outlined, size: 15), label: const Text('Засах'))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton.icon(onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Устгах уу?'), content: const Text('Энэ арга хэмжээг устгах уу?'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Цуцлах')), ElevatedButton(onPressed: () { Navigator.pop(context); _delete(e['id']); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Устгах'))])),
                      icon: const Icon(Icons.delete_outline, size: 15), label: const Text('Устгах'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)))),
                  ]),
                ])));
              })));
  }
}

// ══════════════════════════════════════════════════════════════
// EVENT FORM
// ══════════════════════════════════════════════════════════════
class _EventForm extends StatefulWidget {
  final String clubId; final Map<String, dynamic>? item; final VoidCallback onSaved;
  const _EventForm({required this.clubId, this.item, required this.onSaved});
  @override State<_EventForm> createState() => _EventFormState();
}
class _EventFormState extends State<_EventForm> {
  late TextEditingController _titleCtrl, _descCtrl, _locationCtrl, _hoursCtrl;
  DateTime? _eventDate; bool _saving = false; String? _imageUrl; Uint8List? _imageBytes; String? _imageMime;
  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.item?['title'] ?? ''); _descCtrl = TextEditingController(text: widget.item?['description'] ?? '');
    _locationCtrl = TextEditingController(text: widget.item?['location'] ?? ''); _hoursCtrl = TextEditingController(text: widget.item?['hours']?.toString() ?? '');
    _imageUrl = widget.item?['image_url'];
    if (widget.item?['event_date'] != null) _eventDate = DateTime.tryParse(widget.item!['event_date']);
  }
  @override void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); _locationCtrl.dispose(); _hoursCtrl.dispose(); super.dispose(); }
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: _eventDate != null
          ? TimeOfDay.fromDateTime(_eventDate!)
          : const TimeOfDay(hour: 18, minute: 0),
    );
    if (!mounted) return;
    setState(() {
      _eventDate = t != null
          ? DateTime(d.year, d.month, d.day, t.hour, t.minute)
          : DateTime(d.year, d.month, d.day);
    });
  }
  Future<void> _pickImage() async {
    try {
      final p = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
      if (p == null) return;
      final bytes = await p.readAsBytes();
      if (mounted) setState(() { _imageBytes = bytes; _imageMime = p.mimeType ?? 'image/jpeg'; _imageUrl = null; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Зураг сонгох амжилтгүй: $e'), backgroundColor: Colors.red));
    }
  }
  Future<String?> _uploadImage() async { if (_imageBytes == null) return _imageUrl; final ext = (_imageMime ?? 'image/jpeg').split('/').last; final path = 'events/${widget.clubId}/${DateTime.now().millisecondsSinceEpoch}.$ext'; await supabase.storage.from('announcements').uploadBinary(path, _imageBytes!, fileOptions: FileOptions(contentType: _imageMime ?? 'image/jpeg', upsert: true)); return supabase.storage.from('announcements').getPublicUrl(path); }
  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Гарчиг оруулна уу'))); return; }
    if (_eventDate == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Огноо сонгоно уу'))); return; }
    setState(() => _saving = true);
    try {
      final url = await _uploadImage();
      final data = {'club_id': widget.clubId, 'title': _titleCtrl.text.trim(), 'description': _descCtrl.text.trim(), 'location': _locationCtrl.text.trim(), 'hours': double.tryParse(_hoursCtrl.text.trim()) ?? 0, 'event_date': _eventDate!.toIso8601String(), 'image_url': url, 'created_by': supabase.auth.currentUser?.id};
      if (widget.item == null) {
        await supabase.from('events').insert(data);
      } else {
        await supabase.from('events').update(data).eq('id', widget.item!['id']);
      }
      if (mounted) widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Хадгалах амжилтгүй: $e'),
            backgroundColor: Colors.red, duration: const Duration(seconds: 6)));
      }
    }
  }

  Widget _imagePicker(ThemeColors c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Зураг (заавал биш)', style: TextStyle(fontSize: 13, color: c.textMuted)),
    const SizedBox(height: 8),
    GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 140, width: double.infinity,
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.teal.withOpacity(0.3))),
        child: _imageBytes != null
            ? ClipRRect(borderRadius: BorderRadius.circular(12),
                child: Stack(fit: StackFit.expand, children: [
                  Image.memory(_imageBytes!, fit: BoxFit.cover),
                  Positioned(top: 6, right: 6, child: GestureDetector(
                    onTap: () => setState(() { _imageBytes = null; _imageMime = null; }),
                    child: Container(padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 16)))),
                ]))
            : _imageUrl != null
                ? ClipRRect(borderRadius: BorderRadius.circular(12),
                    child: Stack(fit: StackFit.expand, children: [
                      Image.network(_imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                      Positioned(top: 6, right: 6, child: GestureDetector(
                        onTap: () => setState(() => _imageUrl = null),
                        child: Container(padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 16)))),
                    ]))
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 36, color: c.teal.withOpacity(0.6)),
                    const SizedBox(height: 8),
                    Text('Зураг сонгох', style: TextStyle(color: c.teal.withOpacity(0.7), fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Компьютер болон утаснаас', style: TextStyle(color: c.textMuted, fontSize: 11)),
                  ]),
      ),
    ),
  ]);

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    final dateStr = _eventDate != null
        ? '${_eventDate!.year}.${_eventDate!.month.toString().padLeft(2,'0')}.${_eventDate!.day.toString().padLeft(2,'0')}  ${_eventDate!.hour.toString().padLeft(2,'0')}:${_eventDate!.minute.toString().padLeft(2,'0')}'
        : 'Огноо ба цаг сонгох';
    return Container(decoration: BoxDecoration(color: c.bgCard, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)))),
        Text(widget.item == null ? 'Арга хэмжээ нэмэх' : 'Засах', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: c.textPrimary)),
        const SizedBox(height: 16),
        AppTextField(controller: _titleCtrl, label: 'Гарчиг'), const SizedBox(height: 10),
        AppTextField(controller: _descCtrl, label: 'Тайлбар', maxLines: 3), const SizedBox(height: 10),
        AppTextField(controller: _locationCtrl, label: 'Байршил'), const SizedBox(height: 10),
        AppTextField(controller: _hoursCtrl, label: 'Цагийн тоо', keyboardType: TextInputType.number), const SizedBox(height: 12),
        GestureDetector(onTap: _pickDate, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: c.surface.withOpacity(0.6), borderRadius: BorderRadius.circular(14), border: Border.all(color: _eventDate != null ? c.teal.withOpacity(0.5) : c.border.withOpacity(0.3))),
          child: Row(children: [Icon(Icons.calendar_today_outlined, size: 18, color: _eventDate != null ? c.teal : c.textMuted), const SizedBox(width: 10), Text(dateStr, style: TextStyle(fontSize: 14, color: _eventDate != null ? c.textPrimary : c.textMuted))]))),
        const SizedBox(height: 14),
        _imagePicker(c),
        const SizedBox(height: 16),
        if (_saving) const Center(child: CircularProgressIndicator()) else SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: Text(widget.item == null ? 'Нэмэх' : 'Хадгалах'), style: ElevatedButton.styleFrom(backgroundColor: c.teal, padding: const EdgeInsets.symmetric(vertical: 14)))),
      ])));
  }
}

// ══════════════════════════════════════════════════════════════
// ANNOUNCEMENT FORM
// ══════════════════════════════════════════════════════════════
class _AnnouncementForm extends StatefulWidget {
  final String clubId; final Map<String, dynamic>? item; final VoidCallback onSaved;
  const _AnnouncementForm({required this.clubId, this.item, required this.onSaved});
  @override State<_AnnouncementForm> createState() => _AnnouncementFormState();
}
class _AnnouncementFormState extends State<_AnnouncementForm> {
  late TextEditingController _titleCtrl, _contentCtrl;
  bool _saving = false; String? _imageUrl; Uint8List? _imageBytes; String? _imageMime; DateTime? _eventDate;
  @override void initState() { super.initState(); _titleCtrl = TextEditingController(text: widget.item?['title'] ?? ''); _contentCtrl = TextEditingController(text: widget.item?['content'] ?? ''); _imageUrl = widget.item?['image_url']; if (widget.item?['event_date'] != null) _eventDate = DateTime.tryParse(widget.item!['event_date']); }
  @override void dispose() { _titleCtrl.dispose(); _contentCtrl.dispose(); super.dispose(); }
  Future<void> _pickImage() async {
    try {
      final p = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
      if (p == null) return;
      final bytes = await p.readAsBytes();
      if (mounted) setState(() { _imageBytes = bytes; _imageMime = p.mimeType ?? 'image/jpeg'; _imageUrl = null; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Зураг сонгох амжилтгүй: $e'), backgroundColor: Colors.red));
    }
  }
  Future<String?> _uploadImage() async { if (_imageBytes == null) return _imageUrl; final ext = _imageMime?.split('/').last ?? 'jpg'; final path = 'clubs/${widget.clubId}/${DateTime.now().millisecondsSinceEpoch}.$ext'; await supabase.storage.from('announcements').uploadBinary(path, _imageBytes!, fileOptions: FileOptions(contentType: _imageMime ?? 'image/jpeg', upsert: true)); return supabase.storage.from('announcements').getPublicUrl(path); }
  Future<void> _save(String status) async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Гарчиг болон агуулга оруулна уу'))); return; }
    setState(() => _saving = true);
    try {
      final url = await _uploadImage();
      final data = {'club_id': widget.clubId, 'title': _titleCtrl.text.trim(), 'content': _contentCtrl.text.trim(), 'image_url': url, 'status': status, 'event_date': _eventDate?.toIso8601String(), 'updated_at': DateTime.now().toIso8601String()};
      if (widget.item == null) {
        await supabase.from('announcements').insert(data);
      } else {
        await supabase.from('announcements').update(data).eq('id', widget.item!['id']);
      }
      if (mounted) widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Хадгалах амжилтгүй: $e'),
            backgroundColor: Colors.red, duration: const Duration(seconds: 6)));
      }
    }
  }

  Widget _imagePicker(ThemeColors c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Зураг (заавал биш)', style: TextStyle(fontSize: 13, color: c.textMuted)),
    const SizedBox(height: 8),
    GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 140, width: double.infinity,
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.primary.withOpacity(0.3))),
        child: _imageBytes != null
            ? ClipRRect(borderRadius: BorderRadius.circular(12),
                child: Stack(fit: StackFit.expand, children: [
                  Image.memory(_imageBytes!, fit: BoxFit.cover),
                  Positioned(top: 6, right: 6, child: GestureDetector(
                    onTap: () => setState(() { _imageBytes = null; _imageMime = null; }),
                    child: Container(padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 16)))),
                ]))
            : _imageUrl != null
                ? ClipRRect(borderRadius: BorderRadius.circular(12),
                    child: Stack(fit: StackFit.expand, children: [
                      Image.network(_imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                      Positioned(top: 6, right: 6, child: GestureDetector(
                        onTap: () => setState(() => _imageUrl = null),
                        child: Container(padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 16)))),
                    ]))
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 36, color: c.primary.withOpacity(0.6)),
                    const SizedBox(height: 8),
                    Text('Зураг сонгох', style: TextStyle(color: c.primary.withOpacity(0.7), fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Компьютер болон утаснаас', style: TextStyle(color: c.textMuted, fontSize: 11)),
                  ]),
      ),
    ),
  ]);

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Container(decoration: BoxDecoration(color: c.bgCard, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)))),
        Text(widget.item == null ? 'Мэдээ нэмэх' : 'Мэдээ засах', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: c.textPrimary)),
        const SizedBox(height: 16),
        AppTextField(controller: _titleCtrl, label: 'Гарчиг'), const SizedBox(height: 10),
        AppTextField(controller: _contentCtrl, label: 'Агуулга', maxLines: 5),
        const SizedBox(height: 14),
        _imagePicker(c),
        const SizedBox(height: 20),
        if (_saving) const Center(child: CircularProgressIndicator()) else Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () => _save('draft'), icon: const Icon(Icons.save_outlined, size: 16), label: const Text('Ноорог'))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton.icon(onPressed: () => _save('published'), icon: const Icon(Icons.send_outlined, size: 16), label: const Text('Нийтлэх'), style: ElevatedButton.styleFrom(backgroundColor: c.primary))),
        ]),
      ])));
  }
}

// ══════════════════════════════════════════════════════════════
// HOURS TAB
// ══════════════════════════════════════════════════════════════
class _HoursTab extends StatefulWidget {
  final String clubId;
  const _HoursTab({required this.clubId});
  @override State<_HoursTab> createState() => _HoursTabState();
}
class _HoursTabState extends State<_HoursTab> {
  final _eventService = EventService(); final _hoursService = VolunteerHoursService(); final _adminService = AdminService();
  List<Map<String, dynamic>> _events = []; bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final events = await _eventService.getUpcomingEvents(clubId: widget.clubId); if (mounted) setState(() { _events = events; _loading = false; }); }
  void _showAddHoursDialog(BuildContext context, Map<String, dynamic> event) async {
    final c = context.read<ThemeProvider>().colors;
    final members = await _adminService.getClubMembers(widget.clubId);
    final existingHours = await supabase.from('volunteer_hours').select('user_id').eq('club_id', widget.clubId).eq('event_id', event['id']);
    final alreadyAdded = Set<String>.from((existingHours as List).map((h) => h['user_id'] as String));
    final selected = <String>{};
    if (!context.mounted) return;
    showDialog(context: context, builder: (_) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      backgroundColor: c.bgCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(event['title'] ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)), const SizedBox(height: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: c.teal.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Text('${event['hours']} цаг олгох', style: TextStyle(fontSize: 12, color: c.teal, fontWeight: FontWeight.w600)))]),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Оюутнуудыг сонгоно уу', style: TextStyle(color: c.textMuted, fontSize: 13)), const SizedBox(height: 12),
        ConstrainedBox(constraints: const BoxConstraints(maxHeight: 360), child: ListView.builder(shrinkWrap: true, itemCount: members.length, itemBuilder: (_, i) {
          final raw = members[i]; final u = (raw['users'] as Map<String, dynamic>?) ?? {}; final uid = (raw['user_id'] ?? '') as String; final isDone = alreadyAdded.contains(uid); final name = (u['full_name'] ?? '?').toString();
          return Container(margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: isDone ? c.teal.withOpacity(0.08) : selected.contains(uid) ? c.primary.withOpacity(0.1) : c.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDone ? c.teal.withOpacity(0.3) : selected.contains(uid) ? c.primary.withOpacity(0.4) : c.border.withOpacity(0.3), width: selected.contains(uid) ? 1.5 : 1)),
            child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              leading: _MemberAvatar(avatarUrl: u['avatar_url'] as String?, name: name, isDone: isDone, c: c),
              title: Text(u['full_name'] ?? 'Нэргүй', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDone ? c.teal : c.textPrimary)),
              trailing: isDone ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: c.teal.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle_rounded, size: 14, color: c.teal), const SizedBox(width: 4), Text('Нэмэгдсэн', style: TextStyle(fontSize: 10, color: c.teal, fontWeight: FontWeight.w600))]))
                  : Checkbox(value: selected.contains(uid), activeColor: c.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), onChanged: (v) => setS(() { if (v!) selected.add(uid); else selected.remove(uid); })),
              onTap: isDone ? null : () => setS(() { if (selected.contains(uid)) selected.remove(uid); else selected.add(uid); }),
            ));
        })),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Цуцлах', style: TextStyle(color: c.textMuted))),
        ElevatedButton(onPressed: selected.isEmpty ? null : () async {
          await _hoursService.addHoursBulk(userIds: selected.toList(), clubId: widget.clubId, eventId: event['id'], eventTitle: event['title'], hours: (event['hours'] as num).toDouble());
          if (ctx.mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${selected.length} оюутанд ${event['hours']} цаг нэмлээ'), backgroundColor: c.teal)); }
        }, style: ElevatedButton.styleFrom(backgroundColor: c.teal), child: Text('${selected.length} оюутанд нэмэх')),
      ],
    )));
  }
  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return _loading ? const LoadingView() : _events.isEmpty ? const EmptyState(message: 'Арга хэмжээ байхгүй', icon: Icons.event_outlined)
        : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _events.length, itemBuilder: (_, i) {
            final e = _events[i];
            return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
              leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: c.teal.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.event_rounded, color: c.teal, size: 20)),
              title: Text(e['title'] ?? '', style: TextStyle(fontWeight: FontWeight.w500, color: c.textPrimary)),
              subtitle: Text('${e['hours'] ?? 0} цаг', style: TextStyle(fontSize: 12, color: c.textMuted)),
              trailing: ElevatedButton(onPressed: () => _showAddHoursDialog(context, e), style: ElevatedButton.styleFrom(backgroundColor: c.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), textStyle: const TextStyle(fontSize: 12)), child: const Text('Цаг нэмэх'))));
          });
  }
}

// ══════════════════════════════════════════════════════════════
// MEMBER AVATAR WIDGET
// ══════════════════════════════════════════════════════════════
class _MemberAvatar extends StatelessWidget {
  final String? avatarUrl; final String name; final bool isDone; final ThemeColors c;
  const _MemberAvatar({required this.avatarUrl, required this.name, required this.isDone, required this.c});
  static const _icons = [Icons.person_rounded, Icons.face_rounded, Icons.sentiment_very_satisfied_rounded, Icons.school_rounded, Icons.star_rounded, Icons.rocket_launch_rounded, Icons.auto_awesome_rounded, Icons.psychology_rounded, Icons.eco_rounded, Icons.local_fire_department_rounded, Icons.diamond_rounded, Icons.bolt_rounded, Icons.palette_rounded, Icons.sports_esports_rounded, Icons.music_note_rounded, Icons.sports_basketball_rounded];
  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0] : '?';
    if (avatarUrl != null && avatarUrl!.startsWith('icon:')) { final idx = int.tryParse(avatarUrl!.replaceFirst('icon:', '')) ?? 0; final si = idx.clamp(0, _icons.length - 1); final colors = [c.primary, c.teal, c.accent, c.coral]; final clr = colors[si % colors.length]; return Container(width: 48, height: 48, decoration: BoxDecoration(color: isDone ? c.teal.withOpacity(0.2) : clr.withOpacity(0.2), shape: BoxShape.circle), child: Icon(_icons[si], color: isDone ? c.teal : clr, size: 24)); }
    if (avatarUrl != null && avatarUrl!.isNotEmpty) return Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isDone ? c.teal.withOpacity(0.4) : c.primary.withOpacity(0.3), width: 2)), child: ClipOval(child: Image.network(avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _def(letter))));
    return _def(letter);
  }
  Widget _def(String l) => Container(width: 48, height: 48, decoration: BoxDecoration(gradient: isDone ? LinearGradient(colors: [c.teal, c.teal.withOpacity(0.7)]) : c.accentGradient, shape: BoxShape.circle), child: Center(child: Text(l, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20))));
}

// ══════════════════════════════════════════════════════════════
// REVIEWS TAB
// ══════════════════════════════════════════════════════════════
// ══════════════════════════════════════════════════════════════
// ADMIN REVIEWS PAGE — Dashboard-аас тусдаа дэлгэцээр нээгдэнэ.
// Бүх оюутны сэтгэгдлийг доош scroll-ээр харуулна.
// ══════════════════════════════════════════════════════════════
class _AdminReviewsPage extends StatefulWidget {
  final String clubId;
  const _AdminReviewsPage({required this.clubId});
  @override
  State<_AdminReviewsPage> createState() => _AdminReviewsPageState();
}

class _AdminReviewsPageState extends State<_AdminReviewsPage> {
  final _reviewService = ReviewService();
  List<Map<String, dynamic>> _reviews = [];
  double _avgRating = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final res = await supabase.from('reviews')
        .select('*, users!reviews_user_id_fkey(full_name)')
        .eq('club_id', widget.clubId)
        .order('created_at', ascending: false);
    final all = List<Map<String, dynamic>>.from(res as List);
    final visible = all.where((r) => r['is_visible'] != false).toList();
    if (mounted) setState(() {
      _reviews = all;
      _avgRating = visible.isEmpty
          ? 0
          : visible.fold<double>(0.0, (s, e) => s + (e['rating'] as num).toDouble()) / visible.length;
      _loading = false;
    });
  }

  Future<void> _hideReview(String reviewId) async {
    await _reviewService.hideReview(reviewId);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    final visibleCount = _reviews.where((r) => r['is_visible'] != false).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сэтгэгдэл'),
        actions: [_ThemeSwitchButton()],
      ),
      body: _loading
          ? const LoadingView()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // Дундаж rating header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: c.headerGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.rate_review_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(_avgRating > 0 ? _avgRating.toStringAsFixed(1) : '-',
                              style: const TextStyle(
                                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                            const SizedBox(width: 8),
                            Row(children: List.generate(5, (i) => Icon(
                              i < _avgRating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: const Color(0xFFFFD66B), size: 18))),
                          ]),
                          const SizedBox(height: 4),
                          Text('Нийт $visibleCount сэтгэгдэл',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                        ],
                      )),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  if (_reviews.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(children: [
                        Icon(Icons.rate_review_outlined, size: 48, color: c.textMuted),
                        const SizedBox(height: 10),
                        Text('Сэтгэгдэл байхгүй байна',
                          style: TextStyle(color: c.textMuted, fontSize: 14)),
                      ]),
                    )
                  else
                    ..._reviews.map((r) {
                      final stars = (r['rating'] as num?)?.round() ?? 0;
                      final isVisible = r['is_visible'] != false;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(padding: const EdgeInsets.all(14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Expanded(child: Text(r['users']?['full_name'] ?? 'Оюутан',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14, color: c.textPrimary))),
                              Row(children: List.generate(5, (j) => Icon(
                                j < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                                size: 16, color: const Color(0xFFFFBE45)))),
                              if (isVisible)
                                IconButton(
                                  icon: Icon(Icons.visibility_off_outlined, size: 20, color: c.textMuted),
                                  tooltip: 'Нуух',
                                  padding: const EdgeInsets.only(left: 8),
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _hideReview(r['id'] as String)),
                            ]),
                            if (r['comment'] != null && (r['comment'] as String).isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(r['comment'],
                                style: TextStyle(fontSize: 13, color: c.textMuted, height: 1.5)),
                            ],
                            if (!isVisible)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: c.coral.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8)),
                                  child: Text('Нуугдсан',
                                    style: TextStyle(color: c.coral, fontSize: 10, fontWeight: FontWeight.w600)),
                                ),
                              ),
                          ])),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _ReviewsTab extends StatefulWidget {
  final String clubId;
  const _ReviewsTab({required this.clubId});
  @override State<_ReviewsTab> createState() => _ReviewsTabState();
}
class _ReviewsTabState extends State<_ReviewsTab> {
  final _reviewService = ReviewService(); List<Map<String, dynamic>> _reviews = []; bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final res = await supabase.from('reviews').select('*, users!reviews_user_id_fkey(full_name)').eq('club_id', widget.clubId).order('created_at', ascending: false); if (mounted) setState(() { _reviews = res; _loading = false; }); }
  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return _loading ? const LoadingView() : RefreshIndicator(onRefresh: _load,
      child: _reviews.isEmpty ? const EmptyState(message: 'Сэтгэгдэл байхгүй', icon: Icons.rate_review_outlined)
          : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _reviews.length, itemBuilder: (_, i) {
              final r = _reviews[i]; final stars = (r['rating'] as num?)?.round() ?? 0;
              return Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(r['users']?['full_name'] ?? 'Оюутан', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: c.textPrimary)),
                  Row(children: [Row(children: List.generate(5, (j) => Icon(j < stars ? Icons.star_rounded : Icons.star_outline_rounded, size: 14, color: const Color(0xFFFFBE45)))), if (r['is_visible'] == true) IconButton(icon: Icon(Icons.visibility_off_outlined, size: 18, color: c.textMuted), tooltip: 'Нуух', onPressed: () async { await _reviewService.hideReview(r['id']); _load(); })]),
                ]),
                if (r['comment'] != null && (r['comment'] as String).isNotEmpty) ...[const SizedBox(height: 6), Text(r['comment'], style: TextStyle(fontSize: 13, color: c.textMuted))],
                if (r['is_visible'] == false) Text('Нуугдсан', style: TextStyle(color: c.coral, fontSize: 11)),
              ])));
            }));
  }
}

// ══════════════════════════════════════════════════════════════
// DOT PULSE ANIMATION
// ══════════════════════════════════════════════════════════════
class _DotPulse extends StatefulWidget {
  final int delay; final Color color;
  const _DotPulse({required this.delay, required this.color});
  @override State<_DotPulse> createState() => _DotPulseState();
}
class _DotPulseState extends State<_DotPulse> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl; late Animation<double> _anim;
  @override void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true); _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut); Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _ctrl.forward(); }); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: _anim, builder: (_, __) => Container(width: 7, height: 7, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withOpacity(0.35 + 0.65 * _anim.value))));
}

// ══════════════════════════════════════════════════════════════
// AVATAR PICKER SHEET (my_profile_screen.dart-аас дахин ашиглах)
// ══════════════════════════════════════════════════════════════
class _AvatarPickerSheet extends StatefulWidget {
  final String userId; final String? currentAvatar; final Function(String?) onChanged;
  const _AvatarPickerSheet({required this.userId, required this.currentAvatar, required this.onChanged});
  @override State<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}
class _AvatarPickerSheetState extends State<_AvatarPickerSheet> {
  bool _uploading = false;
  static const _avatarIcons = [Icons.person_rounded, Icons.face_rounded, Icons.sentiment_very_satisfied_rounded, Icons.school_rounded, Icons.star_rounded, Icons.rocket_launch_rounded, Icons.auto_awesome_rounded, Icons.psychology_rounded, Icons.eco_rounded, Icons.local_fire_department_rounded, Icons.diamond_rounded, Icons.bolt_rounded, Icons.palette_rounded, Icons.sports_esports_rounded, Icons.music_note_rounded, Icons.sports_basketball_rounded];

  Future<void> _pickAndUpload() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
    if (p == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final bytes = await p.readAsBytes(); final mime = p.mimeType ?? 'image/jpeg'; final ext = p.name.split('.').last.toLowerCase();
      final path = '${widget.userId}/avatar.$ext';
      await supabase.storage.from('avatars').uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime, upsert: true));
      final url = supabase.storage.from('avatars').getPublicUrl(path);
      widget.onChanged('$url?t=${DateTime.now().millisecondsSinceEpoch}');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Алдаа: $e')));
    } finally { if (mounted) setState(() => _uploading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Container(
      decoration: BoxDecoration(color: c.bgCard, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 24),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)))),
        Text('Профайл зураг', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)),
        const SizedBox(height: 20),
        if (_uploading) const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: CircularProgressIndicator())
        else ...[
          GestureDetector(onTap: _pickAndUpload,
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(gradient: c.accentGradient, borderRadius: BorderRadius.circular(14)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.upload_rounded, color: Colors.white, size: 20), SizedBox(width: 8), Text('Зураг upload хийх', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))]))),
          const SizedBox(height: 20),
          Row(children: [Expanded(child: Divider(color: c.border.withOpacity(0.4))), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('эсвэл icon сонгох', style: TextStyle(fontSize: 12, color: c.textMuted))), Expanded(child: Divider(color: c.border.withOpacity(0.4)))]),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1),
            itemCount: _avatarIcons.length,
            itemBuilder: (_, i) {
              final isSelected = widget.currentAvatar == 'icon:$i';
              final palette = [c.primary, c.teal, c.accent, c.coral]; final iconColor = palette[i % palette.length];
              return GestureDetector(onTap: () { widget.onChanged('icon:$i'); Navigator.pop(context); },
                child: AnimatedContainer(duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(color: isSelected ? iconColor.withOpacity(0.2) : c.surface, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? iconColor : c.border.withOpacity(0.3), width: isSelected ? 2 : 1),
                    boxShadow: isSelected ? [BoxShadow(color: iconColor.withOpacity(0.3), blurRadius: 8)] : []),
                  child: Icon(_avatarIcons[i], color: iconColor, size: 30)));
            },
          ),
          if (widget.currentAvatar != null) ...[
            const SizedBox(height: 16),
            GestureDetector(onTap: () { widget.onChanged(null); Navigator.pop(context); },
              child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: c.coral.withOpacity(0.5))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.delete_outline_rounded, color: c.coral, size: 18), const SizedBox(width: 8), Text('Зураг хасах', style: TextStyle(color: c.coral, fontWeight: FontWeight.w600))]))),
          ],
        ],
      ])),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ADMIN POLLS PAGE — Санал асуулга үүсгэх / удирдах
// ══════════════════════════════════════════════════════════════
class _AdminPollsPage extends StatefulWidget {
  final String clubId, clubName;
  const _AdminPollsPage({required this.clubId, required this.clubName});
  @override
  State<_AdminPollsPage> createState() => _AdminPollsPageState();
}

class _AdminPollsPageState extends State<_AdminPollsPage> {
  List<Map<String, dynamic>> _polls = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await supabase.from('polls')
          .select('*, poll_votes(option_id, user_id)')
          .eq('club_id', widget.clubId)
          .order('created_at', ascending: false);
      if (mounted) setState(() {
        _polls = List<Map<String, dynamic>>.from(res as List);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Polls load алдаа: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showCreateSheet() async {
    final tp = context.read<ThemeProvider>();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: tp,
        child: _CreatePollSheet(clubId: widget.clubId),
      ),
    );
    if (ok == true) _load();
  }

  Future<void> _deletePoll(String pollId) async {
    final c = context.read<ThemeProvider>().colors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.bgCard,
        title: const Text('Устгах уу?'),
        content: const Text('Энэхүү poll-ийг устгахдаа итгэлтэй байна уу?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Цуцлах')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: c.coral),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Устгах')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await supabase.from('polls').delete().eq('id', pollId);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Алдаа: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.clubName} - Санал асуулга')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Шинэ poll'),
        backgroundColor: c.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const LoadingView()
          : _polls.isEmpty
              ? const EmptyState(
                  message: 'Поll байхгүй. Шинэ poll үүсгээрэй',
                  icon: Icons.poll_outlined)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _polls.length,
                    itemBuilder: (_, i) {
                      final poll = _polls[i];
                      final options = (poll['options'] as List?) ?? [];
                      final votes = (poll['poll_votes'] as List?) ?? [];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(child: Text(
                                  poll['question'] ?? '',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary))),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: c.coral, size: 20),
                                  onPressed: () => _deletePoll(poll['id'] as String)),
                              ]),
                              const SizedBox(height: 8),
                              ..._buildResultBars(options, votes, c),
                              const SizedBox(height: 8),
                              Text('${votes.length} саналсан',
                                style: TextStyle(fontSize: 11, color: c.textMuted)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  List<Widget> _buildResultBars(List options, List votes, ThemeColors c) {
    final total = votes.length;
    final counts = <String, int>{};
    for (final v in votes) {
      final oid = v['option_id'] as String?;
      if (oid != null) counts[oid] = (counts[oid] ?? 0) + 1;
    }
    return options.map<Widget>((opt) {
      final m = opt as Map<String, dynamic>;
      final id = m['id'] as String;
      final label = m['label'] as String? ?? '';
      final count = counts[id] ?? 0;
      final pct = total == 0 ? 0.0 : count / total;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.border.withOpacity(0.2)),
          ),
          child: Stack(children: [
            // Progress bar fill
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: pct,
                  child: Container(color: c.primary.withOpacity(0.2)),
                ),
              ),
            ),
            Row(children: [
              Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: c.textPrimary, fontWeight: FontWeight.w600))),
              Text('${(pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12, color: c.textMuted, fontWeight: FontWeight.w700)),
            ]),
          ]),
        ),
      );
    }).toList();
  }
}

// ══════════════════════════════════════════════════════════════
// CREATE POLL SHEET
// ══════════════════════════════════════════════════════════════
class _CreatePollSheet extends StatefulWidget {
  final String clubId;
  const _CreatePollSheet({required this.clubId});
  @override
  State<_CreatePollSheet> createState() => _CreatePollSheetState();
}

class _CreatePollSheetState extends State<_CreatePollSheet> {
  final _qCtrl = TextEditingController();
  final List<TextEditingController> _optCtrls = [
    TextEditingController(), TextEditingController()
  ];
  bool _saving = false;

  @override
  void dispose() {
    _qCtrl.dispose();
    for (final c in _optCtrls) { c.dispose(); }
    super.dispose();
  }

  void _addOption() {
    if (_optCtrls.length >= 6) return;
    setState(() => _optCtrls.add(TextEditingController()));
  }

  void _removeOption(int i) {
    if (_optCtrls.length <= 2) return;
    setState(() {
      _optCtrls[i].dispose();
      _optCtrls.removeAt(i);
    });
  }

  Future<void> _save() async {
    final q = _qCtrl.text.trim();
    if (q.isEmpty) return _err('Асуултаа бичнэ үү');
    final opts = _optCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (opts.length < 2) return _err('Дор хаяж 2 сонголт хэрэгтэй');

    setState(() => _saving = true);
    try {
      // option-уудад id оноох — vote tracking-д ашиглана
      int idx = 0;
      final options = opts.map((label) => {'id': 'opt_${idx++}', 'label': label}).toList();
      await supabase.from('polls').insert({
        'club_id':    widget.clubId,
        'question':   q,
        'options':    options,
        'created_by': supabase.auth.currentUser?.id,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _err('Алдаа: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(
            width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)))),
          Text('Шинэ санал асуулга',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)),
          const SizedBox(height: 16),
          AppTextField(controller: _qCtrl, label: 'Асуулт'),
          const SizedBox(height: 14),
          Text('Сонголтууд', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary)),
          const SizedBox(height: 8),
          ...List.generate(_optCtrls.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(child: AppTextField(controller: _optCtrls[i], label: 'Сонголт ${i + 1}')),
              if (_optCtrls.length > 2) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline_rounded, color: c.coral, size: 20),
                  onPressed: () => _removeOption(i)),
              ],
            ]),
          )),
          if (_optCtrls.length < 6)
            TextButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Сонголт нэмэх')),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
              label: Text(_saving ? 'Илгээж байна...' : 'Үүсгэх'))),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }
}