// lib/screens/student/home_screen.dart
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/theme_and_constants.dart';
import '../../widgets/common_widgets.dart';
import 'my_profile_screen.dart' show AvatarWidget;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showSplash = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  final _pages = [
    const _DashboardTab(),
    const _MyClubsTab(),
    const _CalendarTab(),
    const _AllClubsTab(),
    const _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;

    if (_showSplash) return const _SplashScreen();

    return Container(
      decoration: BoxDecoration(gradient: c.bgGradient),
      child: Scaffold(
        extendBody: false,
        backgroundColor: Colors.transparent,
        body: IndexedStack(index: _currentIndex, children: _pages),

        // ── Pill Bottom Nav ───────────────────────────────────
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            clipBehavior: Clip.none,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(icon: Icons.home_outlined,          selectedIcon: Icons.home_rounded,          index: 0, currentIndex: _currentIndex, colors: c, onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.groups_outlined,        selectedIcon: Icons.groups_rounded,        index: 1, currentIndex: _currentIndex, colors: c, onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.calendar_month_outlined,selectedIcon: Icons.calendar_month_rounded,index: 2, currentIndex: _currentIndex, colors: c, onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.explore_outlined,       selectedIcon: Icons.explore_rounded,       index: 3, currentIndex: _currentIndex, colors: c, onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.person_outline,         selectedIcon: Icons.person_rounded,        index: 4, currentIndex: _currentIndex, colors: c, onTap: (i) => setState(() => _currentIndex = i)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════
// SPLASH SCREEN
// ═══════════════════════════════════════════════════════════
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();
  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const bgColor = Color(0xFFF5F0FF);
    const textColor = Color(0xFFD4C5F0);
    const accentColor = Color(0xFF6C63FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(children: [
        // ── "CLUB" тиле давтагдсан арын фон ───────────────
        Positioned.fill(
          child: OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(9, (row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    'CLUB  CLUB  CLUB  CLUB',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: 2,
                      height: 1.1,
                    ),
                  ),
                )),
              ),
            ),
          ),
        ),

        // ── "HUB" — дунд, metallic gradient ───────────────
        Center(
          child: FadeTransition(
            opacity: _fadeIn,
            child: ScaleTransition(
              scale: _scaleIn,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFB06BFF),
                    Color(0xFF6C63FF),
                    Color(0xFFFF6EC7),
                    Color(0xFF6C63FF),
                    Color(0xFFB06BFF),
                  ],
                  stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                ).createShader(bounds),
                child: Text(
                  'HUB',
                  style: TextStyle(
                    fontSize: size.width * 0.32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -4,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Доод: ХУИС ────────────────────────────────────
        Positioned(
          bottom: 48,
          left: 0, right: 0,
          child: FadeTransition(
            opacity: _fadeIn,
            child: const Text(
              'ClubHub — ХУИС',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9B8EC4),
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Nav Item — pill-exit float + spotlight ───────────────────
class _NavItem extends StatefulWidget {
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
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rise;   // icon дээш гарах
  late Animation<double> _fade;   // spotlight fade

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _rise = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    if (widget.index == widget.currentIndex) _ctrl.forward();
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    widget.index == widget.currentIndex ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  static const _labels = ['Нүүр', 'Миний', 'Хуанли', 'Клубүүд', 'Профайл'];

  @override
  Widget build(BuildContext context) {
    final isSel = widget.index == widget.currentIndex;
    final c     = widget.colors;

    return GestureDetector(
      onTap: () => widget.onTap(widget.index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        height: 64,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = _rise.value; // 0..1
            final offsetY = -14.0 * t; // дээш гарах

            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Spotlight — nav дээд хэсэгт
                if (isSel)
                  Positioned(
                    top: -2,
                    left: 0, right: 0,
                    child: Opacity(
                      opacity: _fade.value,
                      child: CustomPaint(
                        size: const Size(60, 40),
                        painter: _SpotlightPainter(color: const Color(0xFF6C63FF)),
                      ),
                    ),
                  ),

                // Icon circle — дээш хөдлөх
                Positioned(
                  top: 12 + offsetY,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSel ? const Color(0xFF6C63FF) : Colors.transparent,
                      boxShadow: isSel
                          ? [BoxShadow(color: Color(0xFF6C63FF).withOpacity(0.5 * _fade.value), blurRadius: 14)]
                          : [],
                    ),
                    child: Icon(
                      isSel ? widget.selectedIcon : widget.icon,
                      color: isSel ? Colors.white : c.textMuted,
                      size: 20,
                    ),
                  ),
                ),

                // Label — доор хэвээр
                Positioned(
                  bottom: 6,
                  child: Text(
                    widget.index < _labels.length ? _labels[widget.index] : '',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                      color: isSel ? Colors.white : c.textMuted,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Spotlight beam — nav дээд edge-ээс туяа
class _SpotlightPainter extends CustomPainter {
  final Color color;
  const _SpotlightPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // Top bar
    final barPaint = Paint()
      ..color = color.withOpacity(0.95)
      ..style = PaintingStyle.fill;
    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 16, 0, 32, 4),
      const Radius.circular(2));
    canvas.drawRRect(rRect, barPaint);

    // Beam trapezoid
    final path = Path()
      ..moveTo(cx - 6, 4)
      ..lineTo(cx + 6, 4)
      ..lineTo(cx + 24, size.height)
      ..lineTo(cx - 24, size.height)
      ..close();

    canvas.drawPath(path, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.6), color.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
  }

  @override
  bool shouldRepaint(_SpotlightPainter o) => o.color != color;
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
  bool _loading       = true;
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _events        = [];
  List<Map<String, dynamic>> _notifications = [];
  final _pageCtrl      = PageController(viewportFraction: 0.88);
  final _eventPageCtrl = PageController(viewportFraction: 0.88);
  DateTime _calendarMonth = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _pageCtrl.dispose(); _eventPageCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    final hours = await _hoursService.getTotalHours(uid);

    final memberships = await supabase
        .from('club_memberships')
        .select('club_id')
        .eq('user_id', uid)
        .eq('status', 'approved');
    final clubIds = (memberships as List)
        .map((m) => m['club_id'] as String)
        .toList();

    final announcements = clubIds.isEmpty
        ? []
        : await supabase
            .from('announcements')
            .select('*, clubs(name)')
            .eq('status', 'published')
            .inFilter('club_id', clubIds)
            .order('created_at', ascending: false)
            .limit(10);

    final now         = DateTime.now();
    final tomorrowStr = DateTime(now.year, now.month, now.day + 1).toIso8601String();
    final todayStr    = DateTime(now.year, now.month, now.day).toIso8601String();

    final upcomingEvents = await supabase
        .from('events')
        .select('*, clubs(name)')
        .gte('event_date', tomorrowStr)
        .order('event_date', ascending: true)
        .limit(10);

    final recentAnnouncements = clubIds.isEmpty
        ? []
        : await supabase
            .from('announcements')
            .select('*, clubs(name)')
            .eq('status', 'published')
            .inFilter('club_id', clubIds)
            .gte('created_at', todayStr)
            .order('created_at', ascending: false)
            .limit(5);

    final List<Map<String, dynamic>> notifs = [];
    for (final e in (upcomingEvents as List)) {
      final eventDate = DateTime.tryParse(e['event_date'] ?? '');
      final dateStr   = eventDate != null
          ? '${eventDate.year}.${eventDate.month.toString().padLeft(2,'0')}.${eventDate.day.toString().padLeft(2,'0')}'
          : '';
      notifs.add({
        'type': 'event',
        'title': 'Маргааш арга хэмжээ болно',
        'body':  '${e['title'] ?? ''} — ${e['clubs']?['name'] ?? ''}',
        'date':  dateStr,
        'icon':  'event',
        'raw':   e,
      });
    }
    for (final a in (recentAnnouncements as List)) {
      notifs.add({
        'type':  'announcement',
        'title': (a['clubs']?['name'] ?? 'Шинэ мэдээ').toString(),
        'body':  (a['title'] ?? '').toString(),
        'date':  '',
        'icon':  'announcement',
        'raw':   a,
      });
    }

    if (mounted) {
      setState(() {
        _totalHours    = hours;
        _announcements = List<Map<String, dynamic>>.from(announcements as List);
        _events        = List<Map<String, dynamic>>.from(upcomingEvents as List);
        _notifications = notifs;
        _loading       = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final c       = context.watch<ThemeProvider>().colors;
    final name    = (auth.profile?['full_name'] ?? '').toString();

    return RefreshIndicator(
      onRefresh: _load,
      color: c.primary,
      backgroundColor: c.bgCard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GreetingHeader(
              name:          name,
              avatarUrl:     auth.profile?['avatar_url'],
              c:             c,
              auth:          auth,
              notifications: _notifications,
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Сайн дурын цаг ──────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/my-hours'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: c.accentGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: c.primary.withOpacity(0.35),
                            blurRadius: 20, offset: const Offset(0, 8), spreadRadius: -2),
                        ],
                        border: Border.all(color: c.primary.withOpacity(0.3), width: 1.5),
                      ),
                      child: Stack(
                        children: [
                          Positioned(top: -20, right: -10,
                            child: Container(width: 100, height: 100,
                              decoration: BoxDecoration(shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.08)))),
                          Positioned(bottom: -30, right: 40,
                            child: Container(width: 80, height: 80,
                              decoration: BoxDecoration(shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.06)))),
                          Row(
                            children: [
                              Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                                ),
                                child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Нийт сайн дурын цаг',
                                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text(_loading ? '...' : '${_totalHours.toStringAsFixed(1)} цаг',
                                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
                                  ],
                                ),
                              ),
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Клубын үйл ажиллагаа ────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Клубын үйл ажиллагаа',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary)),
                      if (_announcements.isNotEmpty)
                        Text('${_announcements.length} мэдээ',
                          style: TextStyle(fontSize: 12, color: c.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_loading)
                    Container(height: 180,
                      decoration: BoxDecoration(color: c.bgCard, borderRadius: BorderRadius.circular(20)),
                      child: Center(child: CircularProgressIndicator(color: c.primary, strokeWidth: 2)))
                  else if (_announcements.isEmpty)
                    Container(height: 90,
                      decoration: BoxDecoration(color: c.bgCard, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.border.withOpacity(0.3))),
                      child: Center(child: Text('Клубын мэдээ байхгүй байна',
                        style: TextStyle(color: c.textMuted, fontSize: 13))))
                  else
                    SizedBox(height: 200,
                      child: PageView.builder(
                        controller: _pageCtrl,
                        itemCount: _announcements.length,
                        itemBuilder: (_, i) => _AnnouncementCard(announcement: _announcements[i], index: i),
                      )),
                  const SizedBox(height: 24),

                  // ── Арга хэмжээнүүд ──────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Арга хэмжээнүүд',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary)),
                      if (_events.isNotEmpty)
                        Text('${_events.length} арга хэмжээ',
                          style: TextStyle(fontSize: 12, color: c.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_loading)
                    Container(height: 100,
                      decoration: BoxDecoration(color: c.bgCard, borderRadius: BorderRadius.circular(16)),
                      child: Center(child: CircularProgressIndicator(color: c.teal, strokeWidth: 2)))
                  else if (_events.isEmpty)
                    Container(height: 90,
                      decoration: BoxDecoration(color: c.bgCard, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.border.withOpacity(0.3))),
                      child: Center(child: Text('Ирэх арга хэмжээ байхгүй байна',
                        style: TextStyle(color: c.textMuted, fontSize: 13))))
                  else
                    SizedBox(height: 130,
                      child: PageView.builder(
                        controller: _eventPageCtrl,
                        itemCount: _events.length,
                        itemBuilder: (_, i) => _EventCard(event: _events[i], c: c),
                      )),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Announcement Card ────────────────────────────────────────
class _AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> announcement;
  final int index;
  const _AnnouncementCard({required this.announcement, required this.index});

  static const _gradients = [
    [Color(0xFF6C63FF), Color(0xFF00D4FF)],
    [Color(0xFFB06BFF), Color(0xFFFF6EC7)],
    [Color(0xFF00D9A6), Color(0xFF00B4D8)],
    [Color(0xFFFF6B6B), Color(0xFFFFBE45)],
    [Color(0xFF5B54E8), Color(0xFFB06BFF)],
  ];

  @override
  Widget build(BuildContext context) {
    final title    = announcement['title'] ?? '';
    final content  = announcement['content'] ?? '';
    final clubName = announcement['clubs']?['name'] ?? '';
    final imageUrl = announcement['image_url'] as String?;
    final createdAt = announcement['created_at'] != null
        ? DateTime.tryParse(announcement['created_at'])?.toLocal() : null;
    final dateStr = createdAt != null
        ? '${createdAt.year}.${createdAt.month.toString().padLeft(2,'0')}.${createdAt.day.toString().padLeft(2,'0')}' : '';
    final grad = _gradients[index % _gradients.length];

    return Container(
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Color(grad[0].value).withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(fit: StackFit.expand, children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            Image.network(imageUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: grad))))
          else
            Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: grad))),
          Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.72)]))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
              if (clubName.isNotEmpty)
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text(clubName, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600))),
              const SizedBox(height: 6),
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text(content, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
              if (dateStr.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Event Card ───────────────────────────────────────────────
class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final ThemeColors c;
  const _EventCard({required this.event, required this.c});

  void _showDetail(BuildContext context) {
    final tp = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(value: tp, child: _EventDetailSheet(event: event)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title    = event['title'] ?? '';
    final clubName = event['clubs']?['name'] ?? '';
    final location = event['location'] ?? '';
    final hours    = event['hours'];
    final dateRaw  = event['event_date'];
    final imageUrl = event['image_url'] as String?;
    String dateStr = '';
    if (dateRaw != null) {
      final d = DateTime.tryParse(dateRaw)?.toLocal();
      if (d != null) dateStr = '${d.year}.${d.month.toString().padLeft(2,'0')}.${d.day.toString().padLeft(2,'0')}';
    }
    final parts = dateStr.isNotEmpty ? dateStr.split('.') : <String>[];

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: c.bgCard, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.teal.withOpacity(0.25)),
          boxShadow: [BoxShadow(color: c.teal.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(imageUrl, width: 90, height: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildDateBox(parts, c))
                : _buildDateBox(parts, c),
          ),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: c.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              if (clubName.isNotEmpty)
                Text(clubName, style: TextStyle(fontSize: 12, color: c.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (location.isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.location_on_outlined, size: 12, color: c.textMuted),
                  const SizedBox(width: 2),
                  Expanded(child: Text(location, style: TextStyle(fontSize: 11, color: c.textMuted),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ],
            ]),
          )),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (hours != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: c.teal.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Text('${hours}ц', style: TextStyle(fontSize: 12, color: c.teal, fontWeight: FontWeight.w700))),
              const SizedBox(height: 6),
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: c.textMuted),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildDateBox(List<String> parts, ThemeColors c) => Container(
    width: 64, height: double.infinity,
    color: c.teal.withOpacity(0.12),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (parts.length == 3) ...[
        Text(parts[2], style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.teal, height: 1)),
        Text('${parts[1]}/${parts[0].length >= 2 ? parts[0].substring(2) : parts[0]}',
          style: TextStyle(fontSize: 10, color: c.teal.withOpacity(0.8))),
      ] else
        Icon(Icons.event_rounded, color: c.teal, size: 24),
    ]),
  );
}

// ── Event Detail Sheet — дугуй progress + зураг ─────────────
class _EventDetailSheet extends StatefulWidget {
  final Map<String, dynamic> event;
  const _EventDetailSheet({required this.event});
  @override
  State<_EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<_EventDetailSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c        = context.watch<ThemeProvider>().colors;
    final title    = widget.event['title'] ?? '';
    final desc     = widget.event['description'] ?? '';
    final clubName = widget.event['clubs']?['name'] ?? '';
    final location = widget.event['location'] ?? '';
    final hours    = widget.event['hours'];
    final imageUrl = widget.event['image_url'] as String?;
    final dateRaw  = widget.event['event_date'];
    String dateStr = '';
    if (dateRaw != null) {
      final d = DateTime.tryParse(dateRaw)?.toLocal();
      if (d != null) dateStr = '${d.year}.${d.month.toString().padLeft(2,'0')}.${d.day.toString().padLeft(2,'0')}';
    }
    final initial = title.isNotEmpty ? title[0] : '?';

    // Blob color from theme
    final blobColor = c.primary.withOpacity(0.18);
    final blobColor2 = c.accent.withOpacity(0.12);

    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(children: [
          // Handle
          Center(child: Container(width: 36, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)))),

          // Date header
          if (dateStr.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Text(dateStr,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c.textPrimary)),
                const Spacer(),
                if (clubName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: c.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.primary.withOpacity(0.25))),
                    child: Text(clubName,
                      style: TextStyle(fontSize: 12, color: c.primary, fontWeight: FontWeight.w600))),
              ]),
            ),

          const SizedBox(height: 24),

          // Blob with animated ring + image background
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(alignment: Alignment.center, children: [
                // Blob background (event image or gradient)
                ClipOval(
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                                colors: [c.primary.withOpacity(0.3), c.accent.withOpacity(0.2)]))))
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                              colors: [c.primary.withOpacity(0.25), c.accent.withOpacity(0.15)]))),
                ),

                // Dark overlay
                ClipOval(child: Container(
                  color: Colors.black.withOpacity(imageUrl != null ? 0.45 : 0.1))),

                // Animated ring
                AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => CustomPaint(
                    size: Size.infinite,
                    painter: _RingPainter(
                      progress: _anim.value,
                      color: c.primary,
                      trackColor: Colors.white.withOpacity(0.15),
                      strokeWidth: 5,
                    ),
                  ),
                ),

                // Center content
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(title,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: imageUrl != null ? Colors.white : c.textPrimary,
                        height: 1.3)),
                    const SizedBox(height: 12),
                    if (hours != null)
                      Text('$hours цаг',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: imageUrl != null ? Colors.white70 : c.teal)),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.location_on_outlined, size: 13,
                          color: imageUrl != null ? Colors.white60 : c.coral),
                        const SizedBox(width: 3),
                        Flexible(child: Text(location,
                          textAlign: TextAlign.center,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12,
                            color: imageUrl != null ? Colors.white60 : c.coral))),
                      ]),
                    ],
                  ]),
                ),
              ]),
            ),
          ),

          // Description
          if (desc.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(context).padding.bottom + 28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Тайлбар',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary)),
                const SizedBox(height: 8),
                Text(desc, style: TextStyle(fontSize: 14, color: c.textSecondary, height: 1.6)),
              ]),
            )
          else
            SizedBox(height: MediaQuery.of(context).padding.bottom + 28),
        ]),
      ),
    );
  }

  Widget _bgPlaceholder(ThemeColors c, String initial) => Container(
    width: double.infinity, height: 220,
    decoration: BoxDecoration(gradient: c.headerGradient),
    child: Center(child: Text(initial,
      style: const TextStyle(fontSize: 72, color: Colors.white24, fontWeight: FontWeight.w900))),
  );

  Widget _chip(ThemeColors c, IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.25))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _glassChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: Colors.white),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
    ]),
  );
}

// ── Ring painter ──────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    this.strokeWidth = 6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx     = size.width / 2;
    final cy     = size.height / 2;
    final radius = (size.width - strokeWidth) / 2;
    final rect   = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    final paint  = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = strokeWidth;

    canvas.drawArc(rect, -1.5708, 6.2832, false, paint..color = trackColor);
    canvas.drawArc(rect, -1.5708, 6.2832 * progress, false, paint..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
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
              : _MyClubsHeader(memberships: _memberships, c: c),
    );
  }
}

// ── My Clubs Header — grid layout ───────────────────────────
class _MyClubsHeader extends StatelessWidget {
  final List<Map<String, dynamic>> memberships;
  final ThemeColors c;
  const _MyClubsHeader({required this.memberships, required this.c});

  @override
  Widget build(BuildContext context) {
    final grads = [
      c.accentGradient,
      c.headerGradient,
      LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.teal, c.primary]),
      LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.coral, c.accent]),
      LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.primary, c.teal]),
      LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.accent, c.primary]),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Title row
          Row(children: [
            Text('Миний клубүүд',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: c.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20)),
              child: Text('${memberships.length} клуб',
                style: TextStyle(fontSize: 12, color: c.primary, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 20),

            // Grid 2 columns
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: memberships.length,
              itemBuilder: (_, i) {
                final club = memberships[i]['clubs'] as Map<String, dynamic>;
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/club-detail', arguments: club['id']),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: grads[i % grads.length],
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      // Icon
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(13)),
                        child: const Icon(Icons.groups_rounded, color: Colors.white, size: 22)),

                      // Name + category
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(club['name'] ?? '',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8)),
                          child: Text(club['category'] ?? '',
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500))),
                      ]),
                    ]),
                  ),
                );
              },
            ),
        ]),
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
      decoration: BoxDecoration(color: c.bgCard, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 36),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)))),
          Row(children: [
            Icon(Icons.palette_outlined, color: c.primary, size: 20),
            const SizedBox(width: 8),
            Text('Өнгөний загвар', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)),
          ]),
          const SizedBox(height: 16),
          ...AppThemeMode.values.map((mode) {
            final isSelected = mode == current;
            final mc         = ThemePalette.of(mode);
            return _ThemeOption(mode: mode, colors: mc, isSelected: isSelected,
              onTap: () { tp.setTheme(mode); Navigator.pop(context); });
          }),
          const SizedBox(height: 4),
        ]),
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
          color: isSelected ? mode.accentColor.withOpacity(0.1) : colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? mode.accentColor.withOpacity(0.6) : colors.border.withOpacity(0.3),
            width: isSelected ? 1.5 : 1),
        ),
        child: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: colors.accentGradient,
              border: Border.all(color: mode.accentColor.withOpacity(0.5), width: 2),
              boxShadow: isSelected ? [BoxShadow(color: mode.accentColor.withOpacity(0.3), blurRadius: 10)] : [])),
          const SizedBox(width: 14),
          Icon(mode.icon, size: 18, color: mode.accentColor),
          const SizedBox(width: 8),
          Expanded(child: Text(mode.label, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? mode.accentColor : colors.textPrimary))),
          if (isSelected)
            Container(width: 22, height: 22,
              decoration: BoxDecoration(shape: BoxShape.circle, color: mode.accentColor),
              child: const Icon(Icons.check_rounded, size: 14, color: Colors.white)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GREETING HEADER
// ─────────────────────────────────────────────────────────────
class _GreetingHeader extends StatelessWidget {
  final String      name;
  final String?     avatarUrl;
  final ThemeColors c;
  final AuthProvider auth;
  final List<Map<String, dynamic>> notifications;

  const _GreetingHeader({required this.name, required this.avatarUrl, required this.c, required this.auth, required this.notifications});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Өглөөний мэнд,';
    if (h < 17) return 'Өдрийн мэнд,';
    if (h < 21) return 'Оройн мэнд,';
    return 'Шөнийн мэнд,';
  }

  void _showNotifications(BuildContext context) {
    final tp = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(value: tp, child: _NotificationSheet(notifications: notifications)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName = name.split(' ').first;
    final initial   = name.isNotEmpty ? name[0] : '?';
    final hasNotif  = notifications.isNotEmpty;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: c.headerGradient),
        child: Stack(clipBehavior: Clip.hardEdge, children: [
          Positioned(top: -50, right: -40, child: Container(width: 200, height: 200,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.primary.withOpacity(0.25)))),
          Positioned(top: 20, right: 80, child: Container(width: 90, height: 90,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.accent.withOpacity(0.15)))),
          Positioned(top: 60, right: 20, child: Container(width: 50, height: 50,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.primary.withOpacity(0.12)))),
          Positioned(bottom: -30, left: -20, child: Container(width: 130, height: 130,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.primary.withOpacity(0.1)))),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('ClubHub — ХУИС',
                    style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 16, fontWeight: FontWeight.w700)),
                  Row(children: [
                    if (auth.isClubAdmin)
                      GestureDetector(onTap: () => Navigator.pushNamed(context, '/admin'), child: _iconBtn(Icons.admin_panel_settings_outlined)),
                    if (auth.isSuperAdmin)
                      GestureDetector(onTap: () => Navigator.pushNamed(context, '/super-admin'), child: _iconBtn(Icons.shield_outlined)),
                    GestureDetector(
                      onTap: () => _showNotifications(context),
                      child: Stack(clipBehavior: Clip.none, children: [
                        _iconBtn(Icons.notifications_outlined),
                        if (hasNotif)
                          Positioned(top: -2, right: -2,
                            child: Container(width: 16, height: 16,
                              decoration: BoxDecoration(color: c.coral, shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5)),
                              child: Center(child: Text(
                                notifications.length > 9 ? '9+' : '${notifications.length}',
                                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700))))),
                      ]),
                    ),
                  ]),
                ]),
                const SizedBox(height: 24),
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Container(
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.35), width: 3)),
                    child: ClipOval(child: _buildAvatar(initial, 64)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_greeting(), style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('$firstName,',
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -0.5),
                      overflow: TextOverflow.ellipsis),
                  ])),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _iconBtn(IconData icon) => Container(
    width: 36, height: 36, margin: const EdgeInsets.only(left: 8),
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.12),
      border: Border.all(color: Colors.white.withOpacity(0.2))),
    child: Icon(icon, color: Colors.white.withOpacity(0.9), size: 18),
  );

  Widget _buildAvatar(String initial, double size) {
    if (avatarUrl != null && avatarUrl!.startsWith('icon:')) return _iconAvatar(avatarUrl!, size);
    if (avatarUrl != null && avatarUrl!.isNotEmpty)
      return Image.network(avatarUrl!, width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultAvatar(initial, size));
    return _defaultAvatar(initial, size);
  }

  Widget _defaultAvatar(String initial, double size) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, gradient: c.accentGradient),
    child: Center(child: Text(initial, style: TextStyle(fontSize: size * 0.38, color: Colors.white, fontWeight: FontWeight.w700))),
  );

  Widget _iconAvatar(String url, double size) {
    const icons = [
      Icons.person_rounded, Icons.face_rounded, Icons.sentiment_very_satisfied_rounded, Icons.school_rounded,
      Icons.star_rounded, Icons.rocket_launch_rounded, Icons.auto_awesome_rounded, Icons.psychology_rounded,
      Icons.eco_rounded, Icons.local_fire_department_rounded, Icons.diamond_rounded, Icons.bolt_rounded,
      Icons.palette_rounded, Icons.sports_esports_rounded, Icons.music_note_rounded, Icons.sports_basketball_rounded,
    ];
    final idx       = int.tryParse(url.replaceFirst('icon:', '')) ?? 0;
    final safeIdx   = idx.clamp(0, icons.length - 1);
    final colors    = [c.primary, c.teal, c.accent, c.coral];
    final iconColor = colors[safeIdx % colors.length];
    return Container(width: size, height: size, color: iconColor.withOpacity(0.2),
      child: Icon(icons[safeIdx], color: iconColor, size: size * 0.5));
  }
}



// ─────────────────────────────────────────────────────────────
// COLLAPSIBLE CALENDAR WRAPPER
// ─────────────────────────────────────────────────────────────
class _CollapsibleCalendar extends StatefulWidget {
  final List<Map<String, dynamic>> events;
  final DateTime month;
  final DateTime? selectedDay;
  final void Function(DateTime) onMonthChanged;
  final void Function(DateTime, Map<String, dynamic>?) onDaySelected;
  final ThemeColors c;

  const _CollapsibleCalendar({
    required this.events,
    required this.month,
    required this.selectedDay,
    required this.onMonthChanged,
    required this.onDaySelected,
    required this.c,
  });

  @override
  State<_CollapsibleCalendar> createState() => _CollapsibleCalendarState();
}

class _CollapsibleCalendarState extends State<_CollapsibleCalendar>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  // Count events this month
  int get _eventCount => widget.events.where((e) {
    final d = DateTime.tryParse(e['event_date'] ?? '')?.toLocal();
    return d != null && d.year == widget.month.year && d.month == widget.month.month;
  }).length;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border.withOpacity(0.3)),
      ),
      child: Column(children: [
        // ── Header (always visible) ──────────────────────────
        GestureDetector(
          onTap: _toggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: c.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.calendar_month_rounded, color: c.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Арга хэмжээний хуанли',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary)),
                Text('${widget.month.year} оны ${_monthName(widget.month.month)} • $_eventCount арга хэмжээ',
                  style: TextStyle(fontSize: 11, color: c.textMuted)),
              ])),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: Icon(Icons.keyboard_arrow_down_rounded, color: c.textMuted, size: 22),
              ),
            ]),
          ),
        ),

        // ── Expandable content ───────────────────────────────
        SizeTransition(
          sizeFactor: _anim,
          child: Column(children: [
            Divider(height: 1, color: c.border.withOpacity(0.3)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: _EventCalendar(
                events: widget.events,
                month: widget.month,
                selectedDay: widget.selectedDay,
                onMonthChanged: widget.onMonthChanged,
                onDaySelected: widget.onDaySelected,
                c: c,
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  String _monthName(int m) {
    const names = ['1-р', '2-р', '3-р', '4-р', '5-р', '6-р',
                   '7-р', '8-р', '9-р', '10-р', '11-р', '12-р'];
    return '${names[m - 1]} сар';
  }
}

// ─────────────────────────────────────────────────────────────
// EVENT CALENDAR — grid style
// ─────────────────────────────────────────────────────────────
class _EventCalendar extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final DateTime month;
  final DateTime? selectedDay;
  final void Function(DateTime) onMonthChanged;
  final void Function(DateTime, Map<String, dynamic>?) onDaySelected;
  final ThemeColors c;

  const _EventCalendar({
    required this.events,
    required this.month,
    required this.selectedDay,
    required this.onMonthChanged,
    required this.onDaySelected,
    required this.c,
  });

  Map<int, List<Map<String, dynamic>>> _groupByDay() {
    final map = <int, List<Map<String, dynamic>>>{};
    for (final e in events) {
      final d = DateTime.tryParse(e['event_date'] ?? '')?.toLocal();
      if (d != null && d.year == month.year && d.month == month.month) {
        map.putIfAbsent(d.day, () => []).add(e);
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped      = _groupByDay();
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // 1=Mon
    final daysInMonth  = DateTime(month.year, month.month + 1, 0).day;
    final today        = DateTime.now();
    const weekdays     = ['Да', 'Мя', 'Лх', 'Пү', 'Ба', 'Бя', 'Ня'];

    return Column(children: [
      // Month header
      Row(children: [
        GestureDetector(
          onTap: () => onMonthChanged(DateTime(month.year, month.month - 1)),
          child: Container(width: 32, height: 32,
            decoration: BoxDecoration(color: c.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.chevron_left, size: 20, color: c.primary))),
        Expanded(child: Center(child: Text(
          '${month.year} оны ${_mn(month.month)}',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary)))),
        GestureDetector(
          onTap: () => onMonthChanged(DateTime(month.year, month.month + 1)),
          child: Container(width: 32, height: 32,
            decoration: BoxDecoration(color: c.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.chevron_right, size: 20, color: c.primary))),
      ]),
      const SizedBox(height: 14),

      // Weekday row
      Row(children: weekdays.map((d) => Expanded(child: Center(child:
        Text(d, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.textMuted))))).toList()),
      const SizedBox(height: 8),

      // Days grid
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, childAspectRatio: 1.0,
          mainAxisSpacing: 2, crossAxisSpacing: 0),
        itemCount: firstWeekday - 1 + daysInMonth,
        itemBuilder: (_, i) {
          if (i < firstWeekday - 1) return const SizedBox.shrink();
          final day       = i - (firstWeekday - 1) + 1;
          final date      = DateTime(month.year, month.month, day);
          final dayEvents = grouped[day] ?? [];
          final isToday   = date.year == today.year && date.month == today.month && date.day == today.day;
          final isSel     = selectedDay != null &&
              date.year == selectedDay!.year &&
              date.month == selectedDay!.month &&
              date.day == selectedDay!.day;

          return GestureDetector(
            onTap: () => onDaySelected(date, dayEvents.isNotEmpty ? dayEvents.first : null),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSel ? c.primary : isToday ? c.primary.withOpacity(0.15) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$day', style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSel || isToday ? FontWeight.w700 : FontWeight.w400,
                  color: isSel ? Colors.white : isToday ? c.primary : c.textPrimary)),
                if (dayEvents.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Container(width: 5, height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSel ? Colors.white : c.teal)),
                ],
              ]),
            ),
          );
        },
      ),

      // Selected day event tile
      if (selectedDay != null && (grouped[selectedDay!.day] ?? []).isNotEmpty) ...[
        const SizedBox(height: 12),
        Divider(color: c.border.withOpacity(0.3), height: 1),
        const SizedBox(height: 10),
        ...(grouped[selectedDay!.day] ?? []).map((e) => _SelectedEventTile(event: e, c: c)),
      ],
    ]);
  }

  String _mn(int m) {
    const n = ['1-р','2-р','3-р','4-р','5-р','6-р','7-р','8-р','9-р','10-р','11-р','12-р'];
    return '${n[m-1]} сар';
  }
}

class _SelectedEventTile extends StatelessWidget {
  final Map<String, dynamic> event;
  final ThemeColors c;
  const _SelectedEventTile({required this.event, required this.c});

  @override
  Widget build(BuildContext context) {
    final title    = event['title'] ?? '';
    final clubName = event['clubs']?['name'] ?? '';
    final location = event['location'] ?? '';
    final hours    = event['hours'];

    return GestureDetector(
      onTap: () {
        final tp = context.read<ThemeProvider>();
        showModalBottomSheet(
          context: context, isScrollControlled: true,
          useSafeArea: true, backgroundColor: Colors.transparent,
          builder: (_) => ChangeNotifierProvider.value(
            value: tp, child: _EventDetailSheet(event: event)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.primary.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(width: 4, height: 40, decoration: BoxDecoration(
            color: c.primary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary)),
            if (clubName.isNotEmpty)
              Text(clubName, style: TextStyle(fontSize: 11, color: c.textMuted)),
            if (location.isNotEmpty)
              Row(children: [
                Icon(Icons.location_on_outlined, size: 11, color: c.textMuted),
                const SizedBox(width: 2),
                Text(location, style: TextStyle(fontSize: 11, color: c.textMuted)),
              ]),
          ])),
          if (hours != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: c.teal.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Text('${hours}ц', style: TextStyle(fontSize: 11, color: c.teal, fontWeight: FontWeight.w700))),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_ios_rounded, size: 11, color: c.textMuted),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFICATION SHEET
// ─────────────────────────────────────────────────────────────
class _NotificationSheet extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  const _NotificationSheet({required this.notifications});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Container(
      decoration: BoxDecoration(color: c.bgCard, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4,
          margin: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)))),
        Row(children: [
          Icon(Icons.notifications_outlined, color: c.primary, size: 20),
          const SizedBox(width: 8),
          Text('Мэдэгдэл', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)),
          const Spacer(),
          if (notifications.isNotEmpty)
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: c.coral.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Text('${notifications.length} шинэ', style: TextStyle(fontSize: 11, color: c.coral, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 16),
        if (notifications.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Column(children: [
              Icon(Icons.notifications_none_rounded, color: c.textMuted, size: 40),
              const SizedBox(height: 8),
              Text('Мэдэгдэл байхгүй байна', style: TextStyle(color: c.textMuted, fontSize: 13)),
            ])))
        else
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: notifications.length,
              itemBuilder: (_, i) => _NotifItem(notif: notifications[i], c: c),
            ),
          ),
      ]),
    );
  }
}

class _NotifItem extends StatelessWidget {
  final Map<String, dynamic> notif;
  final ThemeColors c;
  const _NotifItem({required this.notif, required this.c});

  @override
  Widget build(BuildContext context) {
    final isEvent = notif['type'] == 'event';
    final color   = isEvent ? c.teal : c.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(isEvent ? Icons.event_rounded : Icons.campaign_rounded, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(notif['title'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary)),
          const SizedBox(height: 2),
          Text(notif['body'] ?? '', style: TextStyle(fontSize: 12, color: c.textSecondary),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          if ((notif['date'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.calendar_today_outlined, size: 11, color: c.textMuted),
              const SizedBox(width: 4),
              Text(notif['date'], style: TextStyle(fontSize: 11, color: c.textMuted)),
            ]),
          ],
        ])),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 3: Хуанли
// ═══════════════════════════════════════════════════════════
class _CalendarTab extends StatefulWidget {
  const _CalendarTab();
  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab> {
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;
  DateTime _month = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final res = await supabase
        .from('events')
        .select('*, clubs(name)')
        .order('event_date', ascending: true);
    if (mounted) setState(() { _events = List<Map<String, dynamic>>.from(res); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return _loading
        ? const LoadingView()
        : RefreshIndicator(
            onRefresh: _load,
            color: c.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: _EventCalendar(
                events: _events,
                month: _month,
                selectedDay: _selectedDay,
                onMonthChanged: (m) => setState(() { _month = m; _selectedDay = null; }),
                onDaySelected: (day, event) {
                  setState(() => _selectedDay = day);
                  if (event != null) {
                    final tp = context.read<ThemeProvider>();
                    showModalBottomSheet(
                      context: context, isScrollControlled: true,
                      useSafeArea: true, backgroundColor: Colors.transparent,
                      builder: (_) => ChangeNotifierProvider.value(
                        value: tp, child: _EventDetailSheet(event: event)),
                    );
                  }
                },
                c: c,
              ),
            ),
          );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB 4: Бүх клубүүд
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
                  ? IconButton(icon: Icon(Icons.clear, size: 18, color: c.textMuted),
                      onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); _load(); })
                  : null,
            ),
            onChanged: (v) { setState(() => _searchQuery = v); _load(); },
          ),
        ),
        SizedBox(
          height: 44,
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
// TAB 5: Профайл
// ═══════════════════════════════════════════════════════════
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthProvider>();
    final tp        = context.watch<ThemeProvider>();
    final c         = tp.colors;
    final profile   = auth.profile;
    final name      = profile?['full_name'] ?? '';
    final initial   = name.isNotEmpty ? name[0] : '?';
    final avatarUrl = profile?['avatar_url'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        children: [
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: Stack(
              children: [
                AvatarWidget(avatarUrl: avatarUrl, initial: initial, c: c, size: 88),
                Positioned(bottom: 0, right: 0,
                  child: Container(width: 26, height: 26,
                    decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle,
                      border: Border.all(color: c.bgDark, width: 2)),
                    child: const Icon(Icons.edit_rounded, size: 13, color: Colors.white))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.textPrimary)),
          const SizedBox(height: 4),
          Text(profile?['email'] ?? auth.user?.email ?? '', style: TextStyle(color: c.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          _menuItem(c, context, Icons.person_outline,              'Профайл засах',   () => Navigator.pushNamed(context, '/profile')),
          _menuItem(c, context, Icons.volunteer_activism_outlined, 'Сайн дурын цаг',  () => Navigator.pushNamed(context, '/my-hours')),
          _menuItem(c, context, Icons.send_outlined,               'Элсэх хүсэлтүүд', () => Navigator.pushNamed(context, '/my-requests')),
          _menuItem(c, context, Icons.star_outline_rounded,        'Миний үнэлгээ',    () => Navigator.pushNamed(context, '/my-reviews')),
          _menuItem(c, context, Icons.lock_outline,                'Нууц үг солих',    () => Navigator.pushNamed(context, '/change-password')),
          _menuItem(c, context, Icons.palette_outlined,            'Загвар солих',     () => _showThemePicker(context, tp)),
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

  Widget _menuItem(ThemeColors c, BuildContext context, IconData icon, String label,
      VoidCallback onTap, {Color? color}) {
    final itemColor = color ?? c.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(color: c.bgCard, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border.withOpacity(0.3))),
        child: ListTile(
          leading: Container(width: 36, height: 36,
            decoration: BoxDecoration(color: itemColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: itemColor, size: 20)),
          title: Text(label, style: TextStyle(fontSize: 14, color: color != null ? color : c.textPrimary, fontWeight: FontWeight.w500)),
          trailing: (color == null || color == c.cyan) ? Icon(Icons.chevron_right, color: c.textMuted, size: 18) : null,
          onTap: onTap,
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context, ThemeProvider tp) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8, maxWidth: double.infinity),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ChangeNotifierProvider.value(value: tp, child: const _ThemePickerSheet()),
    );
  }
}