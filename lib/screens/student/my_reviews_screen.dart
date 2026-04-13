// lib/screens/student/my_reviews_screen.dart
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../utils/theme_and_constants.dart';
import '../../widgets/common_widgets.dart';

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