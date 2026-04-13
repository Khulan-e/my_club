// lib/screens/student/my_hours_screen.dart
// ignore_for_file: use_build_context_synchronously
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/theme_and_constants.dart';
import '../../widgets/common_widgets.dart';

class MyHoursScreen extends StatefulWidget {
  const MyHoursScreen({super.key});
  @override
  State<MyHoursScreen> createState() => _MyHoursScreenState();
}

class _MyHoursScreenState extends State<MyHoursScreen>
    with SingleTickerProviderStateMixin {
  final _hoursService = VolunteerHoursService();
  List<Map<String, dynamic>> _hours = [];
  double _total = 0;
  bool _loading = true;

  late AnimationController _animCtrl;
  late Animation<double> _progressAnim;

  static const double _target = 20;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _progressAnim = const AlwaysStoppedAnimation(0);
    _load();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = supabase.auth.currentUser!.id;
    final results = await Future.wait([
      _hoursService.getUserHours(uid),
      _hoursService.getTotalHours(uid),
    ]);
    if (!mounted) return;

    final total   = results[1] as double;
    final current = total % _target;
    final laps    = (total / _target).floor();
    final endVal  = laps > 0 ? 1.0 : (current / _target).clamp(0.0, 1.0);

    _animCtrl.reset();
    _progressAnim = Tween<double>(begin: 0, end: endVal).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );

    setState(() {
      _hours   = results[0] as List<Map<String, dynamic>>;
      _total   = total;
      _loading = false;
    });
    _animCtrl.forward();
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c        = context.watch<ThemeProvider>().colors;
    final exceeded = _total >= _target;
    final laps     = (_total / _target).floor();

    return Scaffold(
      appBar: AppBar(title: const Text('Сайн дурын цаг')),
      body: _loading
          ? const LoadingView()
          : RefreshIndicator(
              onRefresh: _load,
              color: c.teal,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: c.headerGradient,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: c.primary.withOpacity(0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
                      child: Column(
                        children: [
                          // Circular gauge
                          AnimatedBuilder(
                            animation: _progressAnim,
                            builder: (context, child) {
                              return SizedBox(
                                width: 200,
                                height: 200,
                                child: CustomPaint(
                                  painter: _CircularProgressPainter(
                                    progress:   _progressAnim.value,
                                    trackColor: c.primary.withOpacity(0.15),
                                    fillColor:  exceeded
                                        ? const Color(0xFFFFBE45)
                                        : c.teal,
                                    glowColor: (exceeded
                                        ? const Color(0xFFFFBE45)
                                        : c.teal).withOpacity(0.4),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _total.toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: 42,
                                            fontWeight: FontWeight.w800,
                                            color: c.textPrimary,
                                            height: 1,
                                          ),
                                        ),
                                        Text(
                                          'цаг',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: c.teal,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        exceeded
                                            ? Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFFBE45)
                                                      .withOpacity(0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '×$laps давсан 🎉',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFFFFBE45),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              )
                                            : Text(
                                                '/ ${_target.toInt()} зорилго',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: c.textMuted,
                                                ),
                                              ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),

                          // Stat row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _statItem(
                                c,
                                '${_hours.length}',
                                'Үйл ажиллагаа',
                                Icons.event_rounded,
                              ),
                              Container(
                                width: 1, height: 40,
                                color: c.border.withOpacity(0.3),
                              ),
                              _statItem(
                                c,
                                '${((_total / _target) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                                'Гүйцэтгэл',
                                Icons.trending_up_rounded,
                              ),
                              Container(
                                width: 1, height: 40,
                                color: c.border.withOpacity(0.3),
                              ),
                              exceeded
                                  ? _statItem(
                                      c,
                                      '+${(_total % _target).toStringAsFixed(1)}',
                                      'Нэмэлт цаг',
                                      Icons.add_circle_rounded,
                                    )
                                  : _statItem(
                                      c,
                                      '${_target.toInt()}',
                                      'Зорилтод',
                                      Icons.flag_rounded,
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Үйл ажиллагаанууд ───────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 4, height: 18,
                            decoration: BoxDecoration(
                              color: c.teal,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Үйл ажиллагаанууд',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_hours.isEmpty)
                      const EmptyState(
                        message: 'Сайн дурын цаг байхгүй байна',
                        icon: Icons.volunteer_activism_outlined,
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _hours.length,
                        itemBuilder: (_, i) {
                          final h   = _hours[i];
                          final hrs = (h['hours'] as num?)?.toDouble() ?? 0;
                          return _HoursCard(
                            title:    h['event_title'] ?? '',
                            clubName: h['clubs']?['name'] ?? '',
                            hours:    hrs,
                            date:     _formatDate(h['created_at']),
                            c:        c,
                            index:    i,
                          );
                        },
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statItem(
    ThemeColors c,
    String value,
    String label,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: c.teal, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: c.textSecondary),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Hours Card
// ─────────────────────────────────────────────────────────────
class _HoursCard extends StatelessWidget {
  final String title;
  final String clubName;
  final double hours;
  final String date;
  final ThemeColors c;
  final int index;

  const _HoursCard({
    required this.title,
    required this.clubName,
    required this.hours,
    required this.date,
    required this.c,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final palette = [c.teal, c.primary, c.accent, c.coral];
    final color   = palette[index % palette.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(Icons.event_available_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: c.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.groups_outlined, size: 12, color: c.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        clubName,
                        style: TextStyle(fontSize: 12, color: c.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 11, color: c.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: TextStyle(fontSize: 11, color: c.textMuted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              '+${hours % 1 == 0 ? hours.toInt() : hours}ц',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Circular Progress Painter
// ─────────────────────────────────────────────────────────────
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color  trackColor;
  final Color  fillColor;
  final Color  glowColor;

  const _CircularProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center      = Offset(size.width / 2, size.height / 2);
    final radius      = size.width / 2 - 14;
    const startAngle  = -math.pi / 2;
    const strokeWidth = 12.0;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      math.pi * 2,
      false,
      Paint()
        ..color       = trackColor
        ..strokeWidth = strokeWidth
        ..style       = PaintingStyle.stroke
        ..strokeCap   = StrokeCap.round,
    );

    if (progress <= 0) return;

    final sweepAngle = math.pi * 2 * progress;

    // Glow
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color       = glowColor
        ..strokeWidth = strokeWidth + 8
        ..style       = PaintingStyle.stroke
        ..strokeCap   = StrokeCap.round
        ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Fill
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle:   math.pi * 2,
          colors:     [fillColor.withOpacity(0.6), fillColor],
          transform:  const GradientRotation(-math.pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = strokeWidth
        ..style       = PaintingStyle.stroke
        ..strokeCap   = StrokeCap.round,
    );

    // End dot
    final dotAngle = startAngle + sweepAngle;
    canvas.drawCircle(
      Offset(
        center.dx + radius * math.cos(dotAngle),
        center.dy + radius * math.sin(dotAngle),
      ),
      strokeWidth / 2 + 2,
      Paint()..color = fillColor,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) =>
      old.progress != progress || old.fillColor != fillColor;
}