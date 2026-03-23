import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClubDetailScreen extends StatefulWidget {
  final String clubId;
  const ClubDetailScreen({super.key, required this.clubId});

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _club;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadClub();
  }

  Future<void> _loadClub() async {
    final data = await _supabase
        .from('clubs')
        .select()
        .eq('id', widget.clubId)
        .single();

    setState(() {
      _club = data;
      _loading = false;
    });
  }

  Future<void> _joinClub() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('club_requests').insert({
      'student_id': userId,
      'club_id':    widget.clubId,
      'status':     'pending',
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Хүсэлт илгээгдлээ!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_club?['name'] ?? 'Клуб')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _club == null
              ? const Center(child: Text('Клуб олдсонгүй'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _club!['name'] ?? '',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(_club!['description'] ?? ''),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _joinClub,
                          icon: const Icon(Icons.add),
                          label: const Text('Элсэх хүсэлт илгээх'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}