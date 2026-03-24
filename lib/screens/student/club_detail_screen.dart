// lib/screens/student/club_detail_screen.dart
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/theme_and_constants.dart';
import '../../widgets/common_widgets.dart';

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
    if (mounted) setState(() {
      _club    = results[0] as Map<String, dynamic>?;
      _events  = results[1] as List<Map<String, dynamic>>;
      _reviews = results[2] as List<Map<String, dynamic>>;
      if (results.length > 3) _myReview = results[3] as Map<String, dynamic>?;
      _loading = false;
    });
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