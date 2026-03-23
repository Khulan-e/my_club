// lib/screens/student/my_clubs_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyClubsScreen extends StatefulWidget {
  const MyClubsScreen({super.key});

  @override
  State<MyClubsScreen> createState() => _MyClubsScreenState();
}

class _MyClubsScreenState extends State<MyClubsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _clubs = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _search = '';
  String _selectedCategory = 'all';

  final _categories = const [
    {'key': 'all',          'label': 'Бүгд',        'emoji': '🌐'},
    {'key': 'professional', 'label': 'Мэргэжлийн',  'emoji': '💼'},
    {'key': 'hobby',        'label': 'Сонирхлын',   'emoji': '🎯'},
    {'key': 'art',          'label': 'Урлагийн',    'emoji': '🎨'},
  ];

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    final data = await _supabase
        .from('clubs')
        .select()
        .eq('is_active', true)
        .order('name');

    setState(() {
      _clubs = List<Map<String, dynamic>>.from(data);
      _filtered = _clubs;
      _loading = false;
    });
  }

  void _filter() {
    setState(() {
      _filtered = _clubs.where((c) {
        final matchCat = _selectedCategory == 'all' ||
            c['category'] == _selectedCategory;
        final matchSearch = _search.isEmpty ||
            (c['name'] as String)
                .toLowerCase()
                .contains(_search.toLowerCase());
        return matchCat && matchSearch;
      }).toList();
    });
  }

  String _categoryEmoji(String? cat) {
    switch (cat) {
      case 'professional': return '💼';
      case 'hobby':        return '🎯';
      case 'art':          return '🎨';
      default:             return '🌐';
    }
  }

  String _categoryLabel(String? cat) {
    switch (cat) {
      case 'professional': return 'Мэргэжлийн';
      case 'hobby':        return 'Сонирхлын';
      case 'art':          return 'Урлагийн';
      default:             return '';
    }
  }

  Color _categoryColor(String? cat) {
    switch (cat) {
      case 'professional': return const Color(0xFF534AB7);
      case 'hobby':        return const Color(0xFF1D9E75);
      case 'art':          return const Color(0xFFD85A30);
      default:             return const Color(0xFF534AB7);
    }
  }

  Color _categoryBg(String? cat) {
    switch (cat) {
      case 'professional': return const Color(0xFFEEEDFE);
      case 'hobby':        return const Color(0xFFE1F5EE);
      case 'art':          return const Color(0xFFFAECE7);
      default:             return const Color(0xFFEEEDFE);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        title: const Text('Бүх клубүүд'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Хайлт ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE8E7F5)),
                    ),
                    child: TextField(
                      onChanged: (v) {
                        _search = v;
                        _filter();
                      },
                      decoration: const InputDecoration(
                        hintText: 'Клуб хайх...',
                        prefixIcon: Text('🔍',
                            style: TextStyle(fontSize: 18)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),

                // ── Категори ──────────────────────────────
                SizedBox(
                  height: 52,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: _categories.length,
                    itemBuilder: (context, i) {
                      final cat = _categories[i];
                      final selected =
                          _selectedCategory == cat['key'];
                      return GestureDetector(
                        onTap: () {
                          _selectedCategory = cat['key']!;
                          _filter();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF534AB7)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF534AB7)
                                  : const Color(0xFFE8E7F5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(cat['emoji']!,
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                cat['label']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF1A1A2E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── Клубийн тоо ───────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        '${_filtered.length} клуб',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF888780),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Клубийн жагсаалт ──────────────────────
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('😕',
                                  style: TextStyle(fontSize: 48)),
                              SizedBox(height: 12),
                              Text('Клуб олдсонгүй',
                                  style: TextStyle(
                                      color: Color(0xFF888780))),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              16, 0, 16, 20),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) {
                            final club = _filtered[i];
                            return _ClubCard(
                              club: club,
                              categoryEmoji:
                                  _categoryEmoji(club['category']),
                              categoryLabel:
                                  _categoryLabel(club['category']),
                              categoryColor:
                                  _categoryColor(club['category']),
                              categoryBg:
                                  _categoryBg(club['category']),
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/club-detail',
                                arguments: club['id'],
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

// ── Club Card ─────────────────────────────────────────────────
class _ClubCard extends StatelessWidget {
  final Map<String, dynamic> club;
  final String categoryEmoji;
  final String categoryLabel;
  final Color categoryColor;
  final Color categoryBg;
  final VoidCallback onTap;

  const _ClubCard({
    required this.club,
    required this.categoryEmoji,
    required this.categoryLabel,
    required this.categoryColor,
    required this.categoryBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E7F5), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Лого
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: categoryBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(categoryEmoji,
                    style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            // Мэдээлэл
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    club['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    club['description'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888780),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: categoryBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          categoryLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: categoryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if ((club['avg_rating'] as num?) != null &&
                          (club['avg_rating'] as num) > 0) ...[
                        const Text('⭐',
                            style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 2),
                        Text(
                          (club['avg_rating'] as num)
                              .toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF888780),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      if ((club['member_count'] as int?) != null) ...[
                        const Text('👥',
                            style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 2),
                        Text(
                          '${club['member_count']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF888780),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Text('›',
                style: TextStyle(
                    color: Color(0xFF888780), fontSize: 22)),
          ],
        ),
      ),
    );
  }
}