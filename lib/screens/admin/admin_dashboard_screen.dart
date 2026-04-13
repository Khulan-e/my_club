// lib/screens/admin/admin_dashboard_screen.dart
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
        appBar: AppBar(title: const Text('Клубийн тэргүүн'),
          actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _signOut)]),
        body: const EmptyState(message: 'Танд хуваарилагдсан клуб байхгүй байна',
          icon: Icons.groups_outlined),
      );
    }
    final pages = [
      _DashboardTab(clubId: _managedClubId!),
      _ClubsTab(clubId: _managedClubId!, clubName: _managedClubName ?? ''),
      _RequestsTab(clubId: _managedClubId!),
      _ContentTab(clubId: _managedClubId!),
      _HoursTab(clubId: _managedClubId!),
      _ReviewsTab(clubId: _managedClubId!),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_managedClubName ?? 'Клубийн тэргүүн'),
        actions: [
          _ThemeSwitchButton(),
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: _signOut),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined),   selectedIcon: Icon(Icons.dashboard),   label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.groups_outlined),      selectedIcon: Icon(Icons.groups),      label: 'Клуб'),
          NavigationDestination(icon: Icon(Icons.inbox_outlined),       selectedIcon: Icon(Icons.inbox),       label: 'Хүсэлт'),
          NavigationDestination(icon: Icon(Icons.campaign_outlined),    selectedIcon: Icon(Icons.campaign),    label: 'Контент'),
          NavigationDestination(icon: Icon(Icons.schedule_outlined),    selectedIcon: Icon(Icons.schedule),    label: 'Цаг'),
          NavigationDestination(icon: Icon(Icons.rate_review_outlined), selectedIcon: Icon(Icons.rate_review), label: 'Сэтгэгдэл'),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────
// Theme Switch Button
// ─────────────────────────────────────────
class _ThemeSwitchButton extends StatelessWidget {
  const _ThemeSwitchButton();

  static const _modes = AppThemeMode.values;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final c  = tp.colors;
    final current = tp.mode;

    return GestureDetector(
      onTap: () {
        final nextIndex = (_modes.indexOf(current) + 1) % _modes.length;
        tp.setTheme(_modes[nextIndex]);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.primary.withOpacity(0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(current.icon, size: 16, color: c.primary),
          const SizedBox(width: 4),
          Text(current.label,
            style: TextStyle(fontSize: 11, color: c.primary, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Dashboard tab
// ─────────────────────────────────────────
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
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final club    = await ClubService().getClub(widget.clubId);
    final members = await supabase.from('club_memberships').select('id').eq('club_id', widget.clubId).eq('status', 'approved');
    final pending = await supabase.from('join_requests').select('id').eq('club_id', widget.clubId).eq('status', 'pending');
    final hours   = await supabase.from('volunteer_hours').select('hours').eq('club_id', widget.clubId);
    final reviews = await supabase.from('reviews').select('rating').eq('club_id', widget.clubId).eq('is_visible', true);
    if (mounted) setState(() {
      _club        = club;
      _memberCount = (members as List).length;
      _pendingCount = (pending as List).length;
      _totalHours  = (hours as List).fold(0.0, (s, e) => s + (e['hours'] as num).toDouble());
      _avgRating   = (reviews as List).isEmpty ? 0 : (reviews).fold(0.0, (s, e) => s + (e['rating'] as num).toDouble()) / reviews.length;
      _loading     = false;
    });
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
          if (_club != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: c.headerGradient, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.groups_rounded, color: Colors.white, size: 24)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_club!['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  Text(_club!['category'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                ])),
              ]),
            ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.6,
            children: [
              _statCard(c, 'Гишүүдийн тоо', '$_memberCount', Icons.people_rounded, c.primary),
              _statCard(c, 'Хүлээгдэж буй', '$_pendingCount', Icons.pending_rounded, const Color(0xFFFFBE45)),
              _statCard(c, 'Нийт цаг', _totalHours.toStringAsFixed(1), Icons.schedule_rounded, c.teal),
              _statCard(c, 'Дундаж үнэлгээ', _avgRating > 0 ? _avgRating.toStringAsFixed(1) : '-', Icons.star_rounded, c.coral),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _statCard(ThemeColors c, String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 22),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
    ]),
  );
}

// ─────────────────────────────────────────
// Clubs tab
// ─────────────────────────────────────────
class _ClubsTab extends StatefulWidget {
  final String clubId, clubName;
  const _ClubsTab({required this.clubId, required this.clubName});
  @override
  State<_ClubsTab> createState() => _ClubsTabState();
}

class _ClubsTabState extends State<_ClubsTab> {
  final _adminService = AdminService();
  List<Map<String, dynamic>> _members = [];
  Map<String, dynamic>? _club;
  bool _loading = true;
  late TextEditingController _nameCtrl, _descCtrl, _emailCtrl, _phoneCtrl, _instrCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(); _descCtrl = TextEditingController();
    _emailCtrl = TextEditingController(); _phoneCtrl = TextEditingController();
    _instrCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _instrCtrl.dispose(); super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([ClubService().getClub(widget.clubId), _adminService.getClubMembers(widget.clubId)]);
    if (mounted) {
      final club = results[0] as Map<String, dynamic>?;
      setState(() {
        _club = club; _members = results[1] as List<Map<String, dynamic>>; _loading = false;
        if (club != null) {
          _nameCtrl.text = club['name'] ?? ''; _descCtrl.text = club['description'] ?? '';
          _emailCtrl.text = club['email'] ?? ''; _phoneCtrl.text = club['phone'] ?? '';
          _instrCtrl.text = club['join_instruction'] ?? '';
        }
      });
    }
  }

  Future<void> _save() async {
    final c = context.read<ThemeProvider>().colors;
    await ClubService().updateClub(widget.clubId, {
      'name': _nameCtrl.text.trim(), 'description': _descCtrl.text.trim(),
      'email': _emailCtrl.text.trim(), 'phone': _phoneCtrl.text.trim(),
      'join_instruction': _instrCtrl.text.trim(),
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Амжилттай хадгалагдлаа'), backgroundColor: c.teal));
  }

  String _initial(dynamic name) { final s = (name ?? '').toString(); return s.isNotEmpty ? s[0] : '?'; }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    if (_loading) return const LoadingView();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Клубийн мэдээлэл', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: c.textPrimary)),
        const SizedBox(height: 12),
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
        SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('Хадгалах'))),
        const SizedBox(height: 24),
        Text('Гишүүд (${_members.length})', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: c.textPrimary)),
        const SizedBox(height: 10),
        if (_members.isEmpty)
          const EmptyState(message: 'Гишүүн байхгүй', icon: Icons.people_outline)
        else
          ..._members.map((m) {
            final u = m['users'] as Map<String, dynamic>? ?? {};
            return Card(margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: c.primaryLight,
                  child: Text(_initial(u['full_name']), style: TextStyle(color: c.primary, fontWeight: FontWeight.w600))),
                title: Text(u['full_name'] ?? 'Нэргүй'),
                subtitle: Text(u['student_code'] ?? ''),
                trailing: IconButton(icon: Icon(Icons.person_remove_outlined, color: c.coral), tooltip: 'Хасах',
                  onPressed: () async { await _adminService.removeMember(m['user_id'], widget.clubId); _load(); }),
              ));
          }),
      ]),
    );
  }
}

// ─────────────────────────────────────────
// Requests tab
// ─────────────────────────────────────────
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
              padding: const EdgeInsets.all(16),
              itemCount: _requests.length,
              itemBuilder: (_, i) {
                final r = _requests[i];
                final user = r['users'] as Map<String, dynamic>? ?? {};
                return Card(margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        CircleAvatar(radius: 18, backgroundColor: c.primaryLight,
                          child: Text(_initial(user['full_name']), style: TextStyle(color: c.primary, fontWeight: FontWeight.w600, fontSize: 14))),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(user['full_name'] ?? 'Нэргүй', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('${user['student_code'] ?? ''}  ·  ${user['department'] ?? ''}',
                            style: TextStyle(fontSize: 12, color: c.textMuted)),
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
                    ]),
                  ));
              }),
    );
  }
}

// ─────────────────────────────────────────
// Content tab
// ─────────────────────────────────────────
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
      Container(
        color: c.bgCard,
        child: TabBar(
          controller: _tabCtrl,
          labelColor: c.primary,
          unselectedLabelColor: c.textMuted,
          indicatorColor: c.primary,
          tabs: const [
            Tab(icon: Icon(Icons.campaign_outlined, size: 18), text: 'Клубын мэдээ'),
            Tab(icon: Icon(Icons.event_outlined, size: 18), text: 'Арга хэмжээ'),
          ],
        ),
      ),
      Expanded(child: TabBarView(
        controller: _tabCtrl,
        children: [
          _AnnouncementsTab(clubId: widget.clubId),
          _EventsTab(clubId: widget.clubId),
        ],
      )),
    ]);
  }
}

// ─────────────────────────────────────────
// Announcements sub-tab
// ─────────────────────────────────────────
class _AnnouncementsTab extends StatefulWidget {
  final String clubId;
  const _AnnouncementsTab({required this.clubId});
  @override
  State<_AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<_AnnouncementsTab> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final res = await supabase.from('announcements').select().eq('club_id', widget.clubId).order('created_at', ascending: false);
    if (mounted) setState(() { _items = res; _loading = false; });
  }

  Future<void> _delete(String id) async {
    await supabase.from('announcements').delete().eq('id', id);
    _load();
  }

  void _openForm({Map<String, dynamic>? item}) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _AnnouncementForm(clubId: widget.clubId, item: item, onSaved: () { Navigator.pop(context); _load(); }),
    );
  }

  String _fmt(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return '${d.year}.${d.month.toString().padLeft(2,'0')}.${d.day.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add), label: const Text('Мэдээ нэмэх'),
        backgroundColor: c.primary),
      body: _loading ? const LoadingView() : RefreshIndicator(
        onRefresh: _load,
        child: _items.isEmpty
            ? const EmptyState(message: 'Мэдээ/зарлал байхгүй байна', icon: Icons.campaign_outlined)
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final a = _items[i];
                  final isPublished = a['status'] == 'published';
                  return Card(margin: const EdgeInsets.only(bottom: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (a['image_url'] != null)
                        ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(a['image_url'], height: 160, width: double.infinity, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink())),
                      Padding(padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isPublished ? c.teal.withOpacity(0.12) : const Color(0xFFFFBE45).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6)),
                              child: Text(isPublished ? 'Нийтлэгдсэн' : 'Ноорог',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                  color: isPublished ? c.teal : const Color(0xFFFFBE45)))),
                            const Spacer(),
                            Text(_fmt(a['created_at']), style: TextStyle(fontSize: 11, color: c.textMuted)),
                          ]),
                          const SizedBox(height: 8),
                          Text(a['title'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: c.textPrimary)),
                          const SizedBox(height: 4),
                          Text(a['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: c.textMuted)),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(child: OutlinedButton.icon(onPressed: () => _openForm(item: a),
                              icon: const Icon(Icons.edit_outlined, size: 15), label: const Text('Засах'))),
                            const SizedBox(width: 8),
                            Expanded(child: OutlinedButton.icon(
                              onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(
                                title: const Text('Устгах уу?'),
                                content: const Text('Энэ мэдээг устгах уу?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Цуцлах')),
                                  ElevatedButton(onPressed: () { Navigator.pop(context); _delete(a['id']); },
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Устгах')),
                                ])),
                              icon: const Icon(Icons.delete_outline, size: 15), label: const Text('Устгах'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)))),
                          ]),
                        ])),
                    ]));
                }),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Events sub-tab
// ─────────────────────────────────────────
class _EventsTab extends StatefulWidget {
  final String clubId;
  const _EventsTab({required this.clubId});
  @override
  State<_EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<_EventsTab> {
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final res = await supabase.from('events').select().eq('club_id', widget.clubId).order('event_date', ascending: true);
    if (mounted) setState(() { _events = res; _loading = false; });
  }

  Future<void> _delete(String id) async {
    await supabase.from('events').delete().eq('id', id);
    _load();
  }

  void _openForm({Map<String, dynamic>? item}) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ThemeProvider>(),
        child: _EventForm(clubId: widget.clubId, item: item, onSaved: () { Navigator.pop(context); _load(); }),
      ),
    );
  }

  String _fmt(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    return '${d.year}.${d.month.toString().padLeft(2,'0')}.${d.day.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add), label: const Text('Арга хэмжээ нэмэх'),
        backgroundColor: c.teal),
      body: _loading ? const LoadingView() : RefreshIndicator(
        onRefresh: _load,
        child: _events.isEmpty
            ? const EmptyState(message: 'Арга хэмжээ байхгүй байна', icon: Icons.event_outlined)
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: _events.length,
                itemBuilder: (_, i) {
                  final e = _events[i];
                  final dateStr = _fmt(e['event_date']);
                  return Card(margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(width: 44, height: 44,
                            decoration: BoxDecoration(color: c.teal.withOpacity(0.12), borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: c.teal.withOpacity(0.2))),
                            child: Icon(Icons.event_rounded, color: c.teal, size: 22)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e['title'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: c.textPrimary)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.calendar_today_outlined, size: 12, color: c.teal),
                              const SizedBox(width: 4),
                              Text(dateStr, style: TextStyle(fontSize: 12, color: c.teal, fontWeight: FontWeight.w600)),
                              if ((e['location'] ?? '').isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.location_on_outlined, size: 12, color: c.textMuted),
                                const SizedBox(width: 2),
                                Expanded(child: Text(e['location'] ?? '', style: TextStyle(fontSize: 12, color: c.textMuted), overflow: TextOverflow.ellipsis)),
                              ],
                            ]),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: c.teal.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                            child: Text('${e['hours'] ?? 0}ц', style: TextStyle(fontSize: 12, color: c.teal, fontWeight: FontWeight.w700))),
                        ]),
                        if ((e['description'] ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(e['description'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: c.textMuted)),
                        ],
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: OutlinedButton.icon(onPressed: () => _openForm(item: e),
                            icon: const Icon(Icons.edit_outlined, size: 15), label: const Text('Засах'))),
                          const SizedBox(width: 8),
                          Expanded(child: OutlinedButton.icon(
                            onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(
                              title: const Text('Устгах уу?'),
                              content: const Text('Энэ арга хэмжээг устгах уу?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Цуцлах')),
                                ElevatedButton(onPressed: () { Navigator.pop(context); _delete(e['id']); },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Устгах')),
                              ])),
                            icon: const Icon(Icons.delete_outline, size: 15), label: const Text('Устгах'),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)))),
                        ]),
                      ])));
                }),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Event Form
// ─────────────────────────────────────────
class _EventForm extends StatefulWidget {
  final String clubId;
  final Map<String, dynamic>? item;
  final VoidCallback onSaved;
  const _EventForm({required this.clubId, this.item, required this.onSaved});
  @override
  State<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<_EventForm> {
  late TextEditingController _titleCtrl, _descCtrl, _locationCtrl, _hoursCtrl;
  DateTime? _eventDate;
  bool _saving     = false;
  String? _imageUrl;
  Uint8List? _imageBytes;
  String? _imageMime;

  @override
  void initState() {
    super.initState();
    _titleCtrl    = TextEditingController(text: widget.item?['title'] ?? '');
    _descCtrl     = TextEditingController(text: widget.item?['description'] ?? '');
    _locationCtrl = TextEditingController(text: widget.item?['location'] ?? '');
    _hoursCtrl    = TextEditingController(text: widget.item?['hours']?.toString() ?? '');
    _imageUrl     = widget.item?['image_url'];
    if (widget.item?['event_date'] != null) {
      _eventDate = DateTime.tryParse(widget.item!['event_date']);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _locationCtrl.dispose(); _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now  = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (date != null) setState(() => _eventDate = date);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (picked == null) return;
    if (mounted) setState(() { _imageMime = picked.mimeType ?? 'image/jpeg'; _imageUrl = null; });
    _imageBytes = await picked.readAsBytes();
    if (mounted) setState(() {});
  }

  Future<String?> _uploadImage() async {
    if (_imageBytes == null) return _imageUrl;
    final ext  = (_imageMime ?? 'image/jpeg').split('/').last;
    final path = 'events/${widget.clubId}/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await supabase.storage.from('announcements').uploadBinary(path, _imageBytes!,
      fileOptions: FileOptions(contentType: _imageMime ?? 'image/jpeg', upsert: true));
    return supabase.storage.from('announcements').getPublicUrl(path);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Гарчиг оруулна уу')));
      return;
    }
    if (_eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Огноо сонгоно уу')));
      return;
    }
    setState(() => _saving = true);
    final uploadedUrl = await _uploadImage();
    final data = {
      'club_id':     widget.clubId,
      'title':       _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'location':    _locationCtrl.text.trim(),
      'hours':       double.tryParse(_hoursCtrl.text.trim()) ?? 0,
      'event_date':  _eventDate!.toIso8601String(),
      'image_url':   uploadedUrl,
      'created_by':  supabase.auth.currentUser?.id,
    };
    if (widget.item == null) {
      await supabase.from('events').insert(data);
    } else {
      await supabase.from('events').update(data).eq('id', widget.item!['id']);
    }
    if (mounted) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final c       = context.watch<ThemeProvider>().colors;
    final dateStr = _eventDate != null
        ? '${_eventDate!.year}.${_eventDate!.month.toString().padLeft(2,'0')}.${_eventDate!.day.toString().padLeft(2,'0')}'
        : 'Огноо сонгох';

    return Container(
      decoration: BoxDecoration(color: c.bgCard, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)))),
        Text(widget.item == null ? 'Арга хэмжээ нэмэх' : 'Арга хэмжээ засах',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: c.textPrimary)),
        const SizedBox(height: 16),
        AppTextField(controller: _titleCtrl, label: 'Гарчиг'),
        const SizedBox(height: 10),
        AppTextField(controller: _descCtrl, label: 'Тайлбар', maxLines: 3),
        const SizedBox(height: 10),
        AppTextField(controller: _locationCtrl, label: 'Байршил'),
        const SizedBox(height: 10),
        AppTextField(controller: _hoursCtrl, label: 'Цагийн тоо', keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: c.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _eventDate != null ? c.teal.withOpacity(0.5) : c.border.withOpacity(0.3))),
            child: Row(children: [
              Icon(Icons.calendar_today_outlined, size: 18, color: _eventDate != null ? c.teal : c.textMuted),
              const SizedBox(width: 10),
              Text(dateStr, style: TextStyle(fontSize: 14,
                color: _eventDate != null ? c.textPrimary : c.textMuted,
                fontWeight: _eventDate != null ? FontWeight.w500 : FontWeight.w400)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 16),
        if (_saving)
          const Center(child: CircularProgressIndicator())
        else
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(widget.item == null ? 'Нэмэх' : 'Хадгалах'),
            style: ElevatedButton.styleFrom(backgroundColor: c.teal, padding: const EdgeInsets.symmetric(vertical: 14)))),
      ])),
    );
  }
}

// ─────────────────────────────────────────
// Announcement Form
// ─────────────────────────────────────────
class _AnnouncementForm extends StatefulWidget {
  final String clubId;
  final Map<String, dynamic>? item;
  final VoidCallback onSaved;
  const _AnnouncementForm({required this.clubId, this.item, required this.onSaved});
  @override
  State<_AnnouncementForm> createState() => _AnnouncementFormState();
}

class _AnnouncementFormState extends State<_AnnouncementForm> {
  late TextEditingController _titleCtrl, _contentCtrl;
  bool _saving = false;
  String? _imageUrl;
  Uint8List? _imageBytes;
  String? _imageMime;
  DateTime? _eventDate;

  @override
  void initState() {
    super.initState();
    _titleCtrl   = TextEditingController(text: widget.item?['title']   ?? '');
    _contentCtrl = TextEditingController(text: widget.item?['content'] ?? '');
    _imageUrl    = widget.item?['image_url'];
    if (widget.item?['event_date'] != null) {
      _eventDate = DateTime.tryParse(widget.item!['event_date']);
    }
  }

  @override
  void dispose() { _titleCtrl.dispose(); _contentCtrl.dispose(); super.dispose(); }

  Future<void> _pickDate() async {
    final now  = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: DateTime(now.year + 2),
    );
    if (date != null) setState(() => _eventDate = date);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) setState(() { _imageBytes = bytes; _imageMime = picked.mimeType ?? 'image/jpeg'; _imageUrl = null; });
  }

  Future<String?> _uploadImage() async {
    if (_imageBytes == null) return _imageUrl;
    final ext  = _imageMime?.split('/').last ?? 'jpg';
    final path = 'clubs/${widget.clubId}/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await supabase.storage.from('announcements').uploadBinary(path, _imageBytes!,
      fileOptions: FileOptions(contentType: _imageMime ?? 'image/jpeg', upsert: true));
    return supabase.storage.from('announcements').getPublicUrl(path);
  }

  Future<void> _save(String status) async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Гарчиг болон агуулга оруулна уу')));
      return;
    }
    setState(() => _saving = true);
    final uploadedUrl = await _uploadImage();
    final data = {
      'club_id':    widget.clubId,
      'title':      _titleCtrl.text.trim(),
      'content':    _contentCtrl.text.trim(),
      'image_url':  uploadedUrl,
      'status':     status,
      'event_date': _eventDate?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (widget.item == null) {
      await supabase.from('announcements').insert(data);
    } else {
      await supabase.from('announcements').update(data).eq('id', widget.item!['id']);
    }
    if (mounted) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final c       = context.watch<ThemeProvider>().colors;
    final dateStr = _eventDate != null
        ? '${_eventDate!.year}.${_eventDate!.month.toString().padLeft(2,'0')}.${_eventDate!.day.toString().padLeft(2,'0')}'
        : 'Огноо сонгох (заавал биш)';

    return Container(
      decoration: BoxDecoration(color: c.bgCard, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)))),
        Text(widget.item == null ? 'Мэдээ нэмэх' : 'Мэдээ засах',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: c.textPrimary)),
        const SizedBox(height: 16),
        AppTextField(controller: _titleCtrl, label: 'Гарчиг'),
        const SizedBox(height: 10),
        AppTextField(controller: _contentCtrl, label: 'Агуулга', maxLines: 5),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: c.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _eventDate != null ? c.primary.withOpacity(0.5) : c.border.withOpacity(0.3))),
            child: Row(children: [
              Icon(Icons.calendar_today_outlined, size: 18, color: _eventDate != null ? c.primary : c.textMuted),
              const SizedBox(width: 10),
              Expanded(child: Text(dateStr, style: TextStyle(fontSize: 14,
                color: _eventDate != null ? c.textPrimary : c.textMuted,
                fontWeight: _eventDate != null ? FontWeight.w500 : FontWeight.w400))),
              if (_eventDate != null)
                GestureDetector(onTap: () => setState(() => _eventDate = null),
                  child: Icon(Icons.close, size: 16, color: c.textMuted)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 20),
        if (_saving)
          const Center(child: CircularProgressIndicator())
        else
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => _save('draft'),
              icon: const Icon(Icons.save_outlined, size: 16), label: const Text('Ноорог'))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(onPressed: () => _save('published'),
              icon: const Icon(Icons.send_outlined, size: 16), label: const Text('Нийтлэх'),
              style: ElevatedButton.styleFrom(backgroundColor: c.primary))),
          ]),
      ])),
    );
  }
}

// ─────────────────────────────────────────
// Hours tab — нэг оюутан + нэг арга хэмжээ = нэг бүртгэл
// ─────────────────────────────────────────
class _HoursTab extends StatefulWidget {
  final String clubId;
  const _HoursTab({required this.clubId});
  @override
  State<_HoursTab> createState() => _HoursTabState();
}

class _HoursTabState extends State<_HoursTab> {
  final _eventService = EventService();
  final _hoursService = VolunteerHoursService();
  final _adminService = AdminService();
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final events = await _eventService.getUpcomingEvents(clubId: widget.clubId);
    if (mounted) setState(() { _events = events; _loading = false; });
  }

  void _showAddHoursDialog(BuildContext context, Map<String, dynamic> event) async {
    final c       = context.read<ThemeProvider>().colors;
    final members = await _adminService.getClubMembers(widget.clubId);

    // Энэ арга хэмжээнд аль хэдийн цаг авсан оюутнуудыг татах
    final existingHours = await supabase
        .from('volunteer_hours')
        .select('user_id')
        .eq('club_id', widget.clubId)
        .eq('event_id', event['id']);
    final alreadyAdded = Set<String>.from(
        (existingHours as List).map((h) => h['user_id'] as String));

    final selected = <String>{};
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        backgroundColor: c.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(event['title'] ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: c.teal.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Text('${event['hours']} цаг олгох', style: TextStyle(fontSize: 12, color: c.teal, fontWeight: FontWeight.w600))),
        ]),
        content: SizedBox(
          width: 400,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Оюутнуудыг сонгоно уу', style: TextStyle(color: c.textMuted, fontSize: 13)),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: members.length,
                itemBuilder: (_, i) {
                  final raw = members[i];
                  final u   = (raw['users'] as Map<String, dynamic>?) ?? {};
                  final uid = (raw['user_id'] ?? '') as String;
                  final isDone = alreadyAdded.contains(uid);
                  final initial = (u['full_name'] ?? '?').toString();
                  final letter  = initial.isNotEmpty ? initial[0] : '?';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isDone
                          ? c.teal.withOpacity(0.08)
                          : selected.contains(uid)
                              ? c.primary.withOpacity(0.1)
                              : c.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDone
                            ? c.teal.withOpacity(0.3)
                            : selected.contains(uid)
                                ? c.primary.withOpacity(0.4)
                                : c.border.withOpacity(0.3),
                        width: selected.contains(uid) ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      leading: _MemberAvatar(
                        avatarUrl: u['avatar_url'] as String?,
                        name: u['full_name'] as String? ?? '?',
                        isDone: isDone,
                        c: c,
                      ),
                      title: Text(u['full_name'] ?? 'Нэргүй',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: isDone ? c.teal : c.textPrimary)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if ((u['student_code'] ?? '').toString().isNotEmpty)
                            Text(u['student_code'].toString(),
                              style: TextStyle(fontSize: 12, color: c.textSecondary, fontWeight: FontWeight.w500)),
                          if ((u['department'] ?? '').toString().isNotEmpty)
                            Text(u['department'].toString(),
                              style: TextStyle(fontSize: 11, color: c.textMuted),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                      trailing: isDone
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: c.teal.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.check_circle_rounded, size: 14, color: c.teal),
                                const SizedBox(width: 4),
                                Text('Нэмэгдсэн', style: TextStyle(fontSize: 10, color: c.teal, fontWeight: FontWeight.w600)),
                              ]))
                          : Checkbox(
                              value: selected.contains(uid),
                              activeColor: c.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (v) => setS(() {
                                if (v!) selected.add(uid); else selected.remove(uid);
                              }),
                            ),
                      onTap: isDone ? null : () => setS(() {
                        if (selected.contains(uid)) selected.remove(uid); else selected.add(uid);
                      }),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Цуцлах', style: TextStyle(color: c.textMuted))),
          ElevatedButton(
            onPressed: selected.isEmpty ? null : () async {
              await _hoursService.addHoursBulk(
                userIds: selected.toList(),
                clubId: widget.clubId,
                eventId: event['id'],
                eventTitle: event['title'],
                hours: (event['hours'] as num).toDouble(),
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${selected.length} оюутанд ${event['hours']} цаг нэмлээ'),
                  backgroundColor: c.teal));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: c.teal),
            child: Text('${selected.length} оюутанд нэмэх')),
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return _loading ? const LoadingView() : _events.isEmpty
        ? const EmptyState(message: 'Арга хэмжээ байхгүй', icon: Icons.event_outlined)
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _events.length,
            itemBuilder: (_, i) {
              final e = _events[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(width: 42, height: 42,
                    decoration: BoxDecoration(color: c.teal.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.event_rounded, color: c.teal, size: 20)),
                  title: Text(e['title'] ?? '', style: TextStyle(fontWeight: FontWeight.w500, color: c.textPrimary)),
                  subtitle: Text('${e['hours'] ?? 0} цаг', style: TextStyle(fontSize: 12, color: c.textMuted)),
                  trailing: ElevatedButton(
                    onPressed: () => _showAddHoursDialog(context, e),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.teal, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12)),
                    child: const Text('Цаг нэмэх')),
                ));
            });
  }
}

// ─────────────────────────────────────────
// Member Avatar Widget
// ─────────────────────────────────────────
class _MemberAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final bool isDone;
  final ThemeColors c;

  const _MemberAvatar({
    required this.avatarUrl,
    required this.name,
    required this.isDone,
    required this.c,
  });

  static const _icons = [
    Icons.person_rounded, Icons.face_rounded,
    Icons.sentiment_very_satisfied_rounded, Icons.school_rounded,
    Icons.star_rounded, Icons.rocket_launch_rounded,
    Icons.auto_awesome_rounded, Icons.psychology_rounded,
    Icons.eco_rounded, Icons.local_fire_department_rounded,
    Icons.diamond_rounded, Icons.bolt_rounded,
    Icons.palette_rounded, Icons.sports_esports_rounded,
    Icons.music_note_rounded, Icons.sports_basketball_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0] : '?';

    // Icon avatar
    if (avatarUrl != null && avatarUrl!.startsWith('icon:')) {
      final idx      = int.tryParse(avatarUrl!.replaceFirst('icon:', '')) ?? 0;
      final safeIdx  = idx.clamp(0, _icons.length - 1);
      final colors   = [c.primary, c.teal, c.accent, c.coral];
      final clr      = colors[safeIdx % colors.length];
      return Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: isDone ? c.teal.withOpacity(0.2) : clr.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(_icons[safeIdx], color: isDone ? c.teal : clr, size: 24),
      );
    }

    // Network image avatar
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: isDone ? c.teal.withOpacity(0.4) : c.primary.withOpacity(0.3), width: 2),
        ),
        child: ClipOval(
          child: Image.network(
            avatarUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _defaultAvatar(letter),
          ),
        ),
      );
    }

    // Default gradient avatar
    return _defaultAvatar(letter);
  }

  Widget _defaultAvatar(String letter) => Container(
    width: 48, height: 48,
    decoration: BoxDecoration(
      gradient: isDone
          ? LinearGradient(colors: [c.teal, c.teal.withOpacity(0.7)])
          : c.accentGradient,
      shape: BoxShape.circle,
    ),
    child: Center(child: Text(letter,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20))),
  );
}

// ─────────────────────────────────────────
// Member Avatar Widget
// ─────────────────────────────────────────

// ─────────────────────────────────────────
// Reviews tab
// ─────────────────────────────────────────
class _ReviewsTab extends StatefulWidget {
  final String clubId;
  const _ReviewsTab({required this.clubId});
  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  final _reviewService = ReviewService();
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final res = await supabase.from('reviews').select('*, users!reviews_user_id_fkey(full_name)')
        .eq('club_id', widget.clubId).order('created_at', ascending: false);
    if (mounted) setState(() { _reviews = res; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return _loading ? const LoadingView() : RefreshIndicator(
      onRefresh: _load,
      child: _reviews.isEmpty
          ? const EmptyState(message: 'Сэтгэгдэл байхгүй', icon: Icons.rate_review_outlined)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _reviews.length,
              itemBuilder: (_, i) {
                final r     = _reviews[i];
                final stars = (r['rating'] as num?)?.round() ?? 0;
                return Card(margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(r['users']?['full_name'] ?? 'Оюутан',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: c.textPrimary)),
                        Row(children: [
                          Row(children: List.generate(5, (j) => Icon(
                            j < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 14, color: const Color(0xFFFFBE45)))),
                          if (r['is_visible'] == true)
                            IconButton(icon: Icon(Icons.visibility_off_outlined, size: 18, color: c.textMuted),
                              tooltip: 'Нуух',
                              onPressed: () async { await _reviewService.hideReview(r['id']); _load(); }),
                        ]),
                      ]),
                      if (r['comment'] != null && (r['comment'] as String).isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(r['comment'], style: TextStyle(fontSize: 13, color: c.textMuted)),
                      ],
                      if (r['is_visible'] == false)
                        Text('Нуугдсан', style: TextStyle(color: c.coral, fontSize: 11)),
                    ])));
              }));
  }
}