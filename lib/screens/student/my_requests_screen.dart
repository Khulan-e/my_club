import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final data = await _supabase
        .from('club_requests')
        .select('*, clubs(name)')
        .eq('student_id', userId)
        .order('created_at', ascending: false);

    setState(() {
      _requests = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default:         return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Миний хүсэлтүүд')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('Хүсэлт байхгүй байна'))
              : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (context, i) {
                    final req = _requests[i];
                    final status = req['status'] as String?;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(req['clubs']?['name'] ?? ''),
                        subtitle: Text('Огноо: ${req['created_at']?.toString().substring(0, 10) ?? ''}'),
                        trailing: Chip(
                          label: Text(status ?? 'pending',
                              style: const TextStyle(color: Colors.white)),
                          backgroundColor: _statusColor(status),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}