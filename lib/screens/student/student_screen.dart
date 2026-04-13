// lib/screens/student/student_screen.dart
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/theme_and_constants.dart';
import '../../widgets/common_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _pages = [
    const _DashboardTab(),
    const _MyClubsTab(),
    const _AllClubsTab(),
    const _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final c    = context.watch<ThemeProvider>().colors;

    return Container(
      decoration: BoxDecoration(gradient: c.bgGradient),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('ClubHub — ХУИС'),
          actions: [
            if (auth.isClubAdmin)
              IconButton(
                icon: const Icon(Icons.admin_panel_settings_outlined),
                tooltip: 'Клубын админ самбар',
                onPressed: () => Navigator.pushNamed(context, '/admin'),
              ),
            if (auth.isSuperAdmin)
              IconButton(
                icon: const Icon(Icons.shield_outlined),
                tooltip: 'Супер админ самбар',
                onPressed: () => Navigator.pushNamed(context, '/super-admin'),
              ),
          ],
        ),
        body: IndexedStack(index: _currentIndex, children: _pages),

        // ── Pill Bottom Nav ──────────────────────────────────
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: c.bgCard,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(icon: Icons.home_outlined,    selectedIcon: Icons.home_rounded,    index: 0, currentIndex: _currentIndex, colors: c, onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.groups_outlined,  selectedIcon: Icons.groups_rounded,  index: 1, currentIndex: _currentIndex, colors: c, onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.explore_outlined, selectedIcon: Icons.explore_rounded, index: 2, currentIndex: _currentIndex, colors: c, onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.person_outline,   selectedIcon: Icons.person_rounded,  index: 3, currentIndex: _currentIndex, colors: c, onTap: (i) => setState(() => _currentIndex = i)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav Item — primary тойрог + цагаан icon ──────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final int index;
  final int currentIndex;
  final ThemeColors colors;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.index,
    required this.currentIndex,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isSelected ? 48 : 36,
            height: isSelected ? 48 : 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? colors.primary : Colors.transparent,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colors.primary.withOpacity(0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                      BoxShadow(
                        color: colors.primary.withOpacity(0.15),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? Colors.white : colors.textMuted,
              size: isSelected ? 24 : 21,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 1: Нүүр (Dashboard)
// ═══════════════════════════════════════════════════════════
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();
  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final _hoursService = VolunteerHoursService();
  final _clubService  = ClubService();
  double _totalHours  = 0;
  List<Map<String, dynamic>> _myClubs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    final hours = await _hoursService.getTotalHours(uid);
    final clubs = await supabase
        .from('club_memberships')
        .select('*, clubs(name, category, logo_url)')
        .eq('user_id', uid)
        .eq('status', 'approved')
        .limit(3);
    if (mounted) {
      setState(() {
        _totalHours = hours;
        _myClubs    = List<Map<String, dynamic>>.from(clubs as List);
        _loading    = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final c       = context.watch<ThemeProvider>().colors;
    final name    = (auth.profile?['full_name'] ?? '').toString();
    final initial = name.isNotEmpty ? name[0] : '?';

    return RefreshIndicator(
      onRefresh: _load,
      color: c.primary,
      backgroundColor: c.bgCard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Мэндчилгээ ───────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: c.headerGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.primary.withOpacity(0.2)),
                boxShadow: [BoxShadow(color: c.primary.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: c.accentGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: c.primary.withOpacity(0.4), blurRadius: 12)],
                    ),
                    child: Center(
                      child: Text(initial,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Сайн байна уу,', style: TextStyle(color: c.textSecondary, fontSize: 13)),
                        Text(name,
                          style: TextStyle(color: c.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: c.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(auth.userRole.label,
                            style: TextStyle(color: c.primary, fontSize: 11, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Сайн дурын цаг ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: c.accentGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: c.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Нийт сайн дурын цаг', style: TextStyle(fontSize: 12, color: Colors.white70)),
                      Text(_loading ? '...' : '${_totalHours.toStringAsFixed(1)} цаг',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      onPressed: () => Navigator.pushNamed(context, '/my-hours'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Миний клубүүд ────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Миний клубүүд',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary)),
                TextButton(
                  onPressed: () {
                    final state = context.findAncestorStateOfType<_HomeScreenState>();
                    state?.setState(() => state._currentIndex = 1);
                  },
                  child: const Text('Бүгд', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_loading)
              const LoadingView()
            else if (_myClubs.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.border.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text('Одоогоор элссэн клуб байхгүй байна',
                    style: TextStyle(color: c.textMuted, fontSize: 13)),
                ),
              )
            else
              ..._myClubs.map((m) {
                final club = m['clubs'] as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: c.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.border.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(gradient: c.accentGradient, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.groups_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(club['name'] ?? '',
                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: c.textPrimary)),
                        ),
                        CategoryBadge(category: club['category'] ?? ''),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 20),

            // ── Бүх клубүүд товч ────────────────────────────
            Text('Клубүүд', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: c.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border.withOpacity(0.3)),
              ),
              child: ListTile(
                leading: GlowIcon(icon: Icons.explore_rounded, color: c.primary, size: 20),
                title: Text('Бүх клубүүд үзэх',
                  style: TextStyle(fontWeight: FontWeight.w600, color: c.textPrimary)),
                subtitle: Text('ХУИС-ийн 20 клубын мэдээлэл',
                  style: TextStyle(fontSize: 12, color: c.textSecondary)),
                trailing: Icon(Icons.chevron_right, color: c.textMuted),
                onTap: () {
                  final state = context.findAncestorStateOfType<_HomeScreenState>();
                  state?.setState(() => state._currentIndex = 2);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 2: Миний клубүүд
// ═══════════════════════════════════════════════════════════
class _MyClubsTab extends StatefulWidget {
  const _MyClubsTab();
  @override
  State<_MyClubsTab> createState() => _MyClubsTabState();
}

class _MyClubsTabState extends State<_MyClubsTab> {
  List<Map<String, dynamic>> _memberships = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    final res = await supabase
        .from('club_memberships')
        .select('*, clubs(id, name, category, logo_url, avg_rating, member_count)')
        .eq('user_id', uid)
        .eq('status', 'approved')
        .order('joined_at', ascending: false);
    if (mounted) setState(() { _memberships = List<Map<String, dynamic>>.from(res); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return RefreshIndicator(
      onRefresh: _load,
      color: c.primary,
      child: _loading
          ? const LoadingView()
          : _memberships.isEmpty
              ? const EmptyState(
                  message: 'Элссэн клуб байхгүй байна.\nКлубүүд tab-аас элсэх хүсэлт илгээгээрэй.',
                  icon: Icons.groups_outlined)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _memberships.length,
                  itemBuilder: (_, i) {
                    final m    = _memberships[i];
                    final club = m['clubs'] as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: c.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.border.withOpacity(0.3)),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(gradient: c.accentGradient, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
                          ),
                          title: Text(club['name'] ?? '',
                            style: TextStyle(fontWeight: FontWeight.w600, color: c.textPrimary)),
                          subtitle: CategoryBadge(category: club['category'] ?? ''),
                          trailing: Icon(Icons.chevron_right, color: c.textMuted),
                          onTap: () => Navigator.pushNamed(context, '/club-detail', arguments: club['id']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 3: Бүх клубүүд
// ═══════════════════════════════════════════════════════════
class _AllClubsTab extends StatefulWidget {
  const _AllClubsTab();
  @override
  State<_AllClubsTab> createState() => _AllClubsTabState();
}

class _AllClubsTabState extends State<_AllClubsTab> {
  final _clubService  = ClubService();
  final _searchCtrl   = TextEditingController();
  String _selectedCat = 'all';
  String _searchQuery = '';
  List<Map<String, dynamic>> _clubs = [];
  bool _loading = true;

  static const _cats = [
    {'key': 'all',          'label': 'Бүгд'},
    {'key': 'professional', 'label': 'Мэргэжлийн'},
    {'key': 'hobby',        'label': 'Сонирхлын'},
    {'key': 'art',          'label': 'Урлагийн'},
  ];

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final clubs = _searchQuery.isNotEmpty
        ? await _clubService.searchClubs(_searchQuery)
        : await _clubService.getClubs(category: _selectedCat == 'all' ? null : _selectedCat);
    if (mounted) setState(() { _clubs = clubs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            style: TextStyle(color: c.textPrimary),
            decoration: InputDecoration(
              hintText: 'Клуб хайх...',
              prefixIcon: Icon(Icons.search, size: 20, color: c.textMuted),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 18, color: c.textMuted),
                      onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); _load(); })
                  : null,
            ),
            onChanged: (v) { setState(() => _searchQuery = v); _load(); },
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: _cats.map((cat) => Padding(
              padding: const EdgeInsets.only(right: 6, top: 6, bottom: 6),
              child: ChoiceChip(
                label: Text(cat['label']!),
                selected: _selectedCat == cat['key'],
                onSelected: (_) { setState(() => _selectedCat = cat['key']!); _load(); },
              ),
            )).toList(),
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _clubs.isEmpty
                  ? const EmptyState(message: 'Клуб олдсонгүй', icon: Icons.search_off_rounded)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 320, childAspectRatio: 1.05,
                        crossAxisSpacing: 10, mainAxisSpacing: 10,
                      ),
                      itemCount: _clubs.length,
                      itemBuilder: (_, i) => ClubCard(
                        club: _clubs[i],
                        onTap: () => Navigator.pushNamed(context, '/club-detail', arguments: _clubs[i]['id']),
                      ),
                    ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 4: Профайл
// ═══════════════════════════════════════════════════════════
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final tp      = context.watch<ThemeProvider>();
    final c       = tp.colors;
    final profile = auth.profile;
    final name    = profile?['full_name'] ?? '';
    final initial = name.isNotEmpty ? name[0] : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: c.primary.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: c.primaryLight,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: c.accentGradient),
                child: Center(
                  child: Text(initial,
                    style: const TextStyle(fontSize: 34, color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.textPrimary)),
          const SizedBox(height: 4),
          Text(profile?['email'] ?? '', style: TextStyle(color: c.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: c.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.primary.withOpacity(0.3)),
            ),
            child: Text(profile?['student_code'] ?? '',
              style: TextStyle(fontSize: 12, color: c.primary, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _roleBadgeColor(auth.userRole, c).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _roleBadgeColor(auth.userRole, c).withOpacity(0.3)),
            ),
            child: Text(auth.userRole.label,
              style: TextStyle(fontSize: 11, color: _roleBadgeColor(auth.userRole, c), fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 28),
          _menuItem(c, context, Icons.person_outline,              'Профайл засах',     () => Navigator.pushNamed(context, '/profile')),
          _menuItem(c, context, Icons.volunteer_activism_outlined, 'Сайн дурын цаг',    () => Navigator.pushNamed(context, '/my-hours')),
          _menuItem(c, context, Icons.send_outlined,               'Элсэх хүсэлтүүд',   () => Navigator.pushNamed(context, '/my-requests')),
          _menuItem(c, context, Icons.star_outline_rounded,        'Миний үнэлгээ',      () => Navigator.pushNamed(context, '/my-reviews')),
          _menuItem(c, context, Icons.lock_outline,                'Нууц үг солих',      () => Navigator.pushNamed(context, '/change-password')),
          _menuItem(c, context, Icons.palette_outlined,            'Загвар солих',       () => _showThemePicker(context, tp)),
          if (auth.isClubAdmin)
            _menuItem(c, context, Icons.admin_panel_settings_outlined, 'Клубын админ самбар',
              () => Navigator.pushNamed(context, '/admin'), color: c.cyan),
          if (auth.isSuperAdmin)
            _menuItem(c, context, Icons.shield_outlined, 'Супер админ самбар',
              () => Navigator.pushNamed(context, '/super-admin'), color: c.cyan),
          const SizedBox(height: 8),
          Divider(color: c.border.withOpacity(0.3)),
          const SizedBox(height: 8),
          _menuItem(c, context, Icons.logout, 'Гарах', () async {
            await auth.logout();
            if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
          }, color: c.coral),
        ],
      ),
    );
  }

  static Color _roleBadgeColor(UserRole role, ThemeColors c) {
    switch (role) {
      case UserRole.superAdmin: return c.coral;
      case UserRole.clubAdmin:  return c.teal;
      case UserRole.student:    return c.primary;
    }
  }

  Widget _menuItem(ThemeColors c, BuildContext context, IconData icon, String label,
      VoidCallback onTap, {Color? color}) {
    final itemColor = color ?? c.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: c.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border.withOpacity(0.3)),
        ),
        child: ListTile(
          leading: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: itemColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: itemColor, size: 20),
          ),
          title: Text(label,
            style: TextStyle(fontSize: 14, color: color != null ? color : c.textPrimary, fontWeight: FontWeight.w500)),
          trailing: (color == null || color == c.cyan)
              ? Icon(Icons.chevron_right, color: c.textMuted, size: 18)
              : null,
          onTap: onTap,
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context, ThemeProvider tp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: tp,
        child: const _ThemePickerSheet(),
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
    final bottom  = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 32),
      color: c.bgCard,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
          ),
          Row(
            children: [
              Icon(Icons.palette_outlined, color: c.primary, size: 20),
              const SizedBox(width: 8),
              Text('Өнгөний загвар',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          ...AppThemeMode.values.map((mode) {
            final isSelected = mode == current;
            final mc         = ThemePalette.of(mode);
            return _ThemeOption(
              mode: mode, colors: mc, isSelected: isSelected,
              onTap: () { tp.setTheme(mode); Navigator.pop(context); },
            );
          }),
        ],
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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? mode.accentColor.withOpacity(0.1) : colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? mode.accentColor.withOpacity(0.6) : colors.border.withOpacity(0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
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
          ],
        ),
      ),
    );
  }
}