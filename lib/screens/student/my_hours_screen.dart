import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyHoursScreen extends StatefulWidget {
  const MyHoursScreen({super.key});

  @override
  State<MyHoursScreen> createState() => _MyHoursScreenState();
}

class _MyHoursScreenState extends State<MyHoursScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _hours = [];
  bool _loading = true;
  int _totalHours = 0;

  @override
  void initState() {
    super.initState();
    _loadHours();
  }

  Future<void> _loadHours() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final data = await _supabase
        .from('activity_hours')
        .select('*, clubs(name)')
        .eq('student_id', userId)
        .order('date', ascending: false);

    final list = List<Map<String, dynamic>>.from(data);
    final total = list.fold<int>(
        0, (sum, e) => sum + ((e['hours'] as num?)?.toInt() ?? 0));

    setState(() {
      _hours = list;
      _totalHours = total;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Миний цагууд')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Нийт цаг: $_totalHours ц',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: _hours.isEmpty
                      ? const Center(child: Text('Цаг бүртгэл байхгүй'))
                      : ListView.builder(
                          itemCount: _hours.length,
                          itemBuilder: (context, i) {
                            final h = _hours[i];
                            return ListTile(
                              leading: const Icon(Icons.access_time),
                              title: Text(h['clubs']?['name'] ?? ''),
                              subtitle: Text(h['date']?.toString().substring(0, 10) ?? ''),
                              trailing: Text('${h['hours']} ц'),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}