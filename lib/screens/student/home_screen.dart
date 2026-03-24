// lib/screens/student/home_screen.dart
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  final _pages = const [
    _DashboardTab(),
    _MyClubsTab(),
    _AllClubsTab(),
    _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('ClubHub — ХУИС'),
        actions: [
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              tooltip: 'Админ самбар',
              onPressed: () => Navigator.pushNamed(context, '/admin'),
            ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Нүүр',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Миний клубүүд',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Бүх клубүүд',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профайл',
          ),
        ],
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
  double _totalHours  = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    final hours = await _hoursService.getTotalHours(uid);
    if (mounted) {
      setState(() {
      _totalHours = hours;
      _loading    = false;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final name    = (auth.profile?['full_name'] ?? '').toString();
    final initial = name.isNotEmpty ? name[0] : '?';

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Мэндчилгээ ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(initial,
                      style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Сайн байна уу,',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13)),
                        Text(name,
                          style: const TextStyle(
                            color: Colors.white, fontSize: 18,
                            fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Сайн дурын цаг ──────────────────────────────
            BorderedCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.tealLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.volunteer_activism_rounded,
                      color: AppColors.teal, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Нийт сайн дурын цаг',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      Text(_loading ? '...' : '${_totalHours.toStringAsFixed(1)} цаг',
                        style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700,
                          color: AppColors.teal)),
                    ],
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/my-hours'),
                    child: const Text('Дэлгэрэнгүй'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Мэдээ мэдээлэл ──────────────────────────────
            const Text('Мэдээ мэдээлэл',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            _NewsCard(
              emoji: '📅',
              bgColor: AppColors.primaryLight,
              title: 'Ирэх арга хэмжээнүүд',
              subtitle: 'Клубүүдийн зохион байгуулах арга хэмжээний хуваарь',
              onTap: () {},
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── News Card ─────────────────────────────────────────────────
class _NewsCard extends StatelessWidget {
  final String emoji;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NewsCard({
    required this.emoji,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BorderedCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    )),
                  const SizedBox(height: 3),
                  Text(subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    )),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
              color: AppColors.textMuted, size: 20),
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
    if (mounted) {
      setState(() {
      _memberships = List<Map<String, dynamic>>.from(res);
      _loading = false;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const LoadingView()
          : _memberships.isEmpty
              ? const EmptyState(
                  message: 'Элссэн клуб байхгүй байна.\nКлубүүд tab-аас элсэх хүсэлт илгээгээрэй.',
                  icon: Icons.groups_outlined)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _memberships.length,
                  itemBuilder: (_, i) {
                    final m    = _memberships[i];
                    final club = m['clubs'] as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: BorderedCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.groups_rounded,
                              color: AppColors.primary, size: 22),
                          ),
                          title: Text(club['name'],
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: CategoryBadge(category: club['category']),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pushNamed(context, '/club-detail',
                            arguments: club['id']),
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
        : await _clubService.getClubs(
            category: _selectedCat == 'all' ? null : _selectedCat);
    if (mounted) setState(() { _clubs = clubs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Хайлт ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Клуб хайх...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                        _load();
                      })
                  : null,
            ),
            onChanged: (v) { setState(() => _searchQuery = v); _load(); },
          ),
        ),
        // ── Категори ──────────────────────────────────────
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: _cats.map((c) => Padding(
              padding: const EdgeInsets.only(right: 6, top: 6, bottom: 6),
              child: ChoiceChip(
                label: Text(c['label']!),
                selected: _selectedCat == c['key'],
                onSelected: (_) {
                  setState(() => _selectedCat = c['key']!);
                  _load();
                },
              ),
            )).toList(),
          ),
        ),
        // ── Клубийн жагсаалт ──────────────────────────────
        Expanded(
          child: _loading
              ? const LoadingView()
              : _clubs.isEmpty
                  ? const EmptyState(
                      message: 'Клуб олдсонгүй',
                      icon: Icons.search_off_rounded)
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 320,
                        childAspectRatio: 1.05,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _clubs.length,
                      itemBuilder: (_, i) => ClubCard(
                        club: _clubs[i],
                        onTap: () => Navigator.pushNamed(context, '/club-detail',
                          arguments: _clubs[i]['id']),
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
    final profile = auth.profile;
    final name    = profile?['full_name'] ?? '';
    final initial = name.isNotEmpty ? name[0] : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryLight,
            child: Text(initial,
              style: const TextStyle(
                fontSize: 32, color: AppColors.primary,
                fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          Text(name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          Text(profile?['email'] ?? auth.user?.email ?? '',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(profile?['student_code'] ?? '',
              style: const TextStyle(
                fontSize: 12, color: AppColors.primary,
                fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 24),

          _menuItem(context, Icons.person_outline, 'Профайл засах',
            () => Navigator.pushNamed(context, '/profile')),
          _menuItem(context, Icons.volunteer_activism_outlined, 'Сайн дурын цаг',
            () => Navigator.pushNamed(context, '/my-hours')),
          _menuItem(context, Icons.send_outlined, 'Элсэх хүсэлтүүд',
            () => Navigator.pushNamed(context, '/my-requests')),
          _menuItem(context, Icons.star_outline_rounded, 'Миний үнэлгээ',
            () => Navigator.pushNamed(context, '/my-reviews')),
          _menuItem(context, Icons.lock_outline, 'Нууц үг солих',
            () => Navigator.pushNamed(context, '/change-password')),

          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),

          _menuItem(context, Icons.logout, 'Гарах', () async {
            await auth.logout();
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          }, color: Colors.red),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String label,
      VoidCallback onTap, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BorderedCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(icon, color: color ?? AppColors.primary, size: 22),
          title: Text(label,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500)),
          trailing: color == null
              ? const Icon(Icons.chevron_right, color: AppColors.textMuted)
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}