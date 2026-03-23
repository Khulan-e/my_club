// ═══════════════════════════════════════════════════════════
// lib/screens/student/home_screen.dart
// ═══════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final _clubService = ClubService();
  final _searchCtrl  = TextEditingController();
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
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final clubs = _searchQuery.isNotEmpty
        ? await _clubService.searchClubs(_searchQuery)
        : await _clubService.getClubs(category: _selectedCat == 'all' ? null : _selectedCat);
    if (mounted) setState(() { _clubs = clubs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ClubHub'),
            Text('Сайн уу, ${auth.profile?['full_name'] ?? ''}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: 'Админ',
            onPressed: auth.isAdmin ? () => Navigator.pushNamed(context, '/admin') : null,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline),
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              PopupMenuItem(
                child: const ListTile(leading: Icon(Icons.person_outline), title: Text('Профайл'), contentPadding: EdgeInsets.zero),
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),
              PopupMenuItem(
                child: const ListTile(leading: Icon(Icons.groups_outlined), title: Text('Миний клубүүд'), contentPadding: EdgeInsets.zero),
                onTap: () => Navigator.pushNamed(context, '/my-clubs'),
              ),
              PopupMenuItem(
                child: const ListTile(leading: Icon(Icons.send_outlined), title: Text('Хүсэлтүүд'), contentPadding: EdgeInsets.zero),
                onTap: () => Navigator.pushNamed(context, '/my-requests'),
              ),
              PopupMenuItem(
                child: const ListTile(leading: Icon(Icons.volunteer_activism_outlined), title: Text('Сайн дурын цаг'), contentPadding: EdgeInsets.zero),
                onTap: () => Navigator.pushNamed(context, '/my-hours'),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                child: const ListTile(leading: Icon(Icons.logout), title: Text('Гарах'), contentPadding: EdgeInsets.zero),
                onTap: () async {
                  await auth.logout();
                  if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
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
                        onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); _load(); })
                    : null,
              ),
              onChanged: (v) {
                setState(() => _searchQuery = v);
                _load();
              },
            ),
          ),
          // Category chips
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
                  onSelected: (_) { setState(() => _selectedCat = c['key']!); _load(); },
                ),
              )).toList(),
            ),
          ),
          // Club grid
          Expanded(
            child: _loading
                ? const LoadingView()
                : _clubs.isEmpty
                    ? EmptyState(message: 'Клуб олдсонгүй', icon: Icons.search_off_rounded)
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 320,
                          childAspectRatio: 1.1,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _clubs.length,
                        itemBuilder: (_, i) => ClubCard(
                          club: _clubs[i],
                          onTap: () => Navigator.pushNamed(context, '/club-detail', arguments: _clubs[i]['id']),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════
// lib/screens/student/club_detail_screen.dart
// ═══════════════════════════════════════════════════════════
class ClubDetailScreen extends StatefulWidget {
  final String clubId;
  const ClubDetailScreen({super.key, required this.clubId});
  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  final _clubService    = ClubService();
  final _requestService = JoinRequestService();
  final _reviewService  = ReviewService();

  Map<String, dynamic>? _club;
  List<Map<String, dynamic>> _events  = [];
  List<Map<String, dynamic>> _reviews = [];
  Map<String, dynamic>? _myReview;
  bool _loading = true;
  bool _sending = false;

  final _msgCtrl     = TextEditingController();
  final _reviewCtrl  = TextEditingController();
  double _myRating   = 5;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = supabase.auth.currentUser?.id;
    final results = await Future.wait([
      _clubService.getClub(widget.clubId),
      _clubService.getClubEvents(widget.clubId),
      _clubService.getClubReviews(widget.clubId),
      if (userId != null) _reviewService.getMyReview(userId, widget.clubId),
    ]);
    if (mounted) {
      setState(() {
      _club    = results[0] as Map<String, dynamic>?;
      _events  = results[1] as List<Map<String, dynamic>>;
      _reviews = results[2] as List<Map<String, dynamic>>;
      if (results.length > 3) _myReview = results[3] as Map<String, dynamic>?;
      _loading = false;
    });
    }
  }

  Future<void> _sendRequest() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      final auth = context.read<AuthProvider>();
      await _requestService.sendRequest(
        userId: auth.user!.id,
        clubId: widget.clubId,
        clubName: _club!['name'],
        message: _msgCtrl.text.trim(),
        userData: auth.profile!,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Хүсэлт амжилттай илгээгдлээ'), backgroundColor: AppColors.teal),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showJoinDialog() {
    _msgCtrl.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Элсэх хүсэлт'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_club!['name']} клубт элсэх хүсэлт илгээх',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: _msgCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Өөрийн тухай болон элсэх шалтгаан',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Цуцлах')),
          ElevatedButton(
            onPressed: _sending ? null : _sendRequest,
            child: _sending
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Илгээх'),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog() {
    if (_myReview != null) {
      _reviewCtrl.text = _myReview!['comment'] ?? '';
      _myRating = (_myReview!['rating'] as num).toDouble();
    }
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(_myReview == null ? 'Үнэлгээ өгөх' : 'Үнэлгээ засах'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(
                    i < _myRating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.amber, size: 32),
                  onPressed: () => setS(() => _myRating = i + 1.0),
                )),
              ),
              TextField(
                controller: _reviewCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Сэтгэгдэл', alignLabelWithHint: true),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Цуцлах')),
            ElevatedButton(
              onPressed: () async {
                final userId = supabase.auth.currentUser!.id;
                await _reviewService.upsertReview(
                  userId: userId,
                  clubId: widget.clubId,
                  rating: _myRating,
                  comment: _reviewCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              child: const Text('Хадгалах'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingView());
    if (_club == null) return const Scaffold(body: Center(child: Text('Клуб олдсонгүй')));

    return Scaffold(
      appBar: AppBar(
        title: Text(_club!['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_outline_rounded),
            tooltip: 'Үнэлгээ өгөх',
            onPressed: _showReviewDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.groups_rounded, color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_club!['name'],
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          CategoryBadge(category: _club!['category']),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.star_rounded, size: 16, color: AppColors.amber),
                            const SizedBox(width: 4),
                            Text('${(_club!['avg_rating'] ?? 0).toStringAsFixed(1)}  ·  ${_club!['member_count']} гишүүн',
                              style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Тухай
            _section('Тухай', _club!['description'] ?? 'Мэдээлэл байхгүй'),
            const SizedBox(height: 12),

            // Холбоо барих
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Холбоо барих', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    _infoRow(Icons.email_outlined, _club!['email'] ?? '-'),
                    _infoRow(Icons.phone_outlined, _club!['phone'] ?? '-'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Элсэх заавар
            _section('Элсэх заавар', _club!['join_instruction'] ?? 'Клубтэй холбогдоно уу'),
            const SizedBox(height: 12),

            // Ирэх арга хэмжээ
            if (_events.isNotEmpty) ...[
              const Text('Ирэх арга хэмжээнүүд', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ..._events.map((e) => _eventTile(e)),
              const SizedBox(height: 12),
            ],

            // Сэтгэгдэл
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Сэтгэгдэл', style: TextStyle(fontWeight: FontWeight.w600)),
                TextButton.icon(
                  onPressed: _showReviewDialog,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(_myReview == null ? 'Үнэлэх' : 'Засах'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_reviews.isEmpty)
              const Text('Сэтгэгдэл байхгүй байна',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13))
            else
              ..._reviews.map((r) => _reviewTile(r)),

            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showJoinDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.send_rounded),
        label: const Text('Элсэх хүсэлт'),
      ),
    );
  }

  Widget _section(String title, String body) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5)),
        ],
      ),
    ),
  );

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Icon(icon, size: 16, color: AppColors.textMuted),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontSize: 13)),
    ]),
  );

  Widget _eventTile(Map<String, dynamic> e) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.event_rounded, color: AppColors.primary, size: 20),
      ),
      title: Text(e['title'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: Text('${e['location'] ?? ''}  ·  ${e['hours']} цаг',
        style: const TextStyle(fontSize: 12)),
    ),
  );

  Widget _reviewTile(Map<String, dynamic> r) {
    final stars = (r['rating'] as num).round();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r['users']?['full_name'] ?? 'Оюутан',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                Row(children: List.generate(5, (i) =>
                  Icon(i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 14, color: AppColors.amber))),
              ],
            ),
            if (r['comment'] != null && (r['comment'] as String).isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(r['comment'], style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ],
          ],
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════
// lib/screens/student/my_profile_screen.dart
// ═══════════════════════════════════════════════════════════
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
  bool _editing = false;
  bool _saving  = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<AuthProvider>().profile;
    _nameCtrl  = TextEditingController(text: p?['full_name'] ?? '');
    _phoneCtrl = TextEditingController(text: p?['phone'] ?? '');
    _deptCtrl  = TextEditingController(text: p?['department'] ?? '');
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

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Миний профайл'),
        actions: [
          if (!_editing)
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => setState(() => _editing = true)),
          if (_editing)
            TextButton(onPressed: _saving ? null : _save, child: const Text('Хадгалах')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        (profile?['full_name'] ?? '?').substring(0, 1),
                        style: const TextStyle(fontSize: 32, color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(profile?['full_name'] ?? '',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    Text(profile?['email'] ?? '',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _infoCard('Хувийн мэдээлэл', [
                _editing
                    ? AppTextField(controller: _nameCtrl, label: 'Нэр', validator: (v) => v!.isEmpty ? 'Нэр оруулна уу' : null)
                    : _row('Нэр', profile?['full_name'] ?? '-'),
                const SizedBox(height: 10),
                _editing
                    ? AppTextField(controller: _phoneCtrl, label: 'Утас', keyboardType: TextInputType.phone)
                    : _row('Утас', profile?['phone'] ?? '-'),
              ]),
              const SizedBox(height: 12),

              _infoCard('Сургалтын мэдээлэл', [
                _row('Оюутны код', profile?['student_code'] ?? '-'),
                const SizedBox(height: 8),
                _row('Сургууль', profile?['school'] ?? '-'),
                const SizedBox(height: 8),
                _editing
                    ? AppTextField(controller: _deptCtrl, label: 'Тэнхим / анги')
                    : _row('Тэнхим', profile?['department'] ?? '-'),
              ]),
              const SizedBox(height: 12),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.lock_outline, color: AppColors.primary),
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

  Widget _infoCard(String title, List<Widget> children) => Card(
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

  Widget _row(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
    ],
  );
}


// ═══════════════════════════════════════════════════════════
// lib/screens/student/my_hours_screen.dart
// ═══════════════════════════════════════════════════════════
class MyHoursScreen extends StatefulWidget {
  const MyHoursScreen({super.key});
  @override
  State<MyHoursScreen> createState() => _MyHoursScreenState();
}

class _MyHoursScreenState extends State<MyHoursScreen> {
  final _hoursService = VolunteerHoursService();
  List<Map<String, dynamic>> _hours = [];
  double _total = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = supabase.auth.currentUser!.id;
    final results = await Future.wait([
      _hoursService.getUserHours(uid),
      _hoursService.getTotalHours(uid),
    ]);
    if (mounted) {
      setState(() {
      _hours   = results[0] as List<Map<String, dynamic>>;
      _total   = results[1] as double;
      _loading = false;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сайн дурын цаг')),
      body: _loading ? const LoadingView() : Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.volunteer_activism_rounded, color: AppColors.teal, size: 40),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_total.toStringAsFixed(1)} цаг',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.teal)),
                    const Text('нийт сайн дурын цаг',
                      style: TextStyle(color: AppColors.teal, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _hours.isEmpty
                ? const EmptyState(message: 'Сайн дурын цаг байхгүй байна', icon: Icons.volunteer_activism_outlined)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _hours.length,
                    itemBuilder: (_, i) {
                      final h = _hours[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.event_available_rounded, color: AppColors.teal, size: 20),
                          ),
                          title: Text(h['event_title'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                          subtitle: Text(h['clubs']?['name'] ?? '', style: const TextStyle(fontSize: 12)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(12)),
                            child: Text('+${h['hours']} цаг',
                              style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════
// lib/screens/student/my_requests_screen.dart
// ═══════════════════════════════════════════════════════════
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});
  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final _reqService = JoinRequestService();
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = supabase.auth.currentUser!.id;
    final reqs = await _reqService.getUserRequests(uid);
    if (mounted) setState(() { _requests = reqs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Элсэх хүсэлтүүд')),
      body: _loading ? const LoadingView() : _requests.isEmpty
          ? const EmptyState(message: 'Илгээсэн хүсэлт байхгүй', icon: Icons.send_outlined)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _requests.length,
              itemBuilder: (_, i) {
                final r = _requests[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.groups_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r['clubs']?['name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(height: 2),
                              CategoryBadge(category: r['clubs']?['category'] ?? ''),
                            ],
                          ),
                        ),
                        StatusBadge(status: r['status']),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}


// ═══════════════════════════════════════════════════════════
// lib/screens/student/my_reviews_screen.dart
// ═══════════════════════════════════════════════════════════
class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});
  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  final _reviewService = ReviewService();
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = supabase.auth.currentUser!.id;
    final reviews = await _reviewService.getUserReviews(uid);
    if (mounted) setState(() { _reviews = reviews; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Миний үнэлгээ')),
      body: _loading ? const LoadingView() : _reviews.isEmpty
          ? const EmptyState(message: 'Үнэлгээ байхгүй байна', icon: Icons.star_outline_rounded)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _reviews.length,
              itemBuilder: (_, i) {
                final r = _reviews[i];
                final stars = (r['rating'] as num).round();
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(r['clubs']?['name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                            Row(children: List.generate(5, (j) =>
                              Icon(j < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                                size: 16, color: AppColors.amber))),
                          ],
                        ),
                        if (r['comment'] != null) ...[
                          const SizedBox(height: 6),
                          Text(r['comment'],
                            style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}


// ═══════════════════════════════════════════════════════════
// lib/screens/student/my_clubs_screen.dart
// ═══════════════════════════════════════════════════════════
class MyClubsScreen extends StatefulWidget {
  const MyClubsScreen({super.key});
  @override
  State<MyClubsScreen> createState() => _MyClubsScreenState();
}

class _MyClubsScreenState extends State<MyClubsScreen> {
  List<Map<String, dynamic>> _memberships = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final uid = supabase.auth.currentUser!.id;
    final res = await supabase
        .from('club_memberships')
        .select('*, clubs(name, category, logo_url, avg_rating, member_count)')
        .eq('user_id', uid)
        .eq('status', 'approved')
        .order('joined_at', ascending: false);
    if (mounted) setState(() { _memberships = res; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Миний клубүүд')),
      body: _loading ? const LoadingView() : _memberships.isEmpty
          ? const EmptyState(message: 'Элссэн клуб байхгүй байна', icon: Icons.groups_outlined)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _memberships.length,
              itemBuilder: (_, i) {
                final m = _memberships[i];
                final club = m['clubs'] as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.groups_rounded, color: AppColors.primary, size: 22),
                    ),
                    title: Text(club['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: CategoryBadge(category: club['category']),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(context, '/club-detail', arguments: m['club_id']),
                  ),
                );
              },
            ),
    );
  }
}