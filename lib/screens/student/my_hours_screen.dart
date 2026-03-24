// lib/screens/student/my_hours_screen.dart
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/theme_and_constants.dart';
import '../../widgets/common_widgets.dart';

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
    if (mounted) setState(() {
      _hours   = results[0] as List<Map<String, dynamic>>;
      _total   = results[1] as double;
      _loading = false;
    });
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