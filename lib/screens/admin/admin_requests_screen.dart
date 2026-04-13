// lib/screens/admin/admin_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/theme_and_constants.dart';
import '../../widgets/common_widgets.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen>
    with SingleTickerProviderStateMixin {
  final _db = Supabase.instance.client;
  late TabController _tabController;

  bool _loading = true;
  List<Map<String, dynamic>> _all = [];

  List<Map<String, dynamic>> get _pending  => _all.where((r) => r['status'] == 'pending').toList();
  List<Map<String, dynamic>> get _approved => _all.where((r) => r['status'] == 'approved').toList();
  List<Map<String, dynamic>> get _rejected => _all.where((r) => r['status'] == 'rejected').toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? _error;

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _db
          .from('join_requests')
          .select('''
            id, status, message, requested_at,
            student:users!join_requests_user_id_fkey(id, full_name, student_code, department),
            club:clubs!join_requests_club_id_fkey(id, name, category)
          ''')
          .order('requested_at', ascending: false);

      if (mounted) {
        setState(() {
          _all     = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ AdminRequests load error: $e');
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _updateStatus(String requestId, String status) async {
    try {
      await _db.from('join_requests').update({
        'status':      status,
        'reviewed_by': _db.auth.currentUser!.id,
      }).eq('id', requestId);

      if (status == 'approved') {
        final req = _all.firstWhere((r) => r['id'] == requestId);
        await _db.from('club_memberships').upsert({
          'club_id':   req['club']['id'],
          'user_id':   req['student']['id'],
          'status':    'approved',
          'joined_at': DateTime.now().toIso8601String(),
        });
      }

      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'approved' ? 'Хүсэлт зөвшөөрөгдлөө' : 'Хүсэлт татгалзагдлаа'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ));
      }
    } catch (e) {
      debugPrint('❌ AdminRequests update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Алдаа: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showDetail(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RequestDetailSheet(
        request: request,
        onApprove: () { Navigator.pop(context); _updateStatus(request['id'], 'approved'); },
        onReject:  () { Navigator.pop(context); _updateStatus(request['id'], 'rejected'); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Алдаа: $_error', style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Дахин оролдох'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Хүлээж буй (${_pending.length})'),
            Tab(text: 'Зөвшөөрсөн (${_approved.length})'),
            Tab(text: 'Татгалзсан (${_rejected.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _RequestList(requests: _pending,  onTap: _showDetail, showActions: true,  onApprove: (id) => _updateStatus(id, 'approved'), onReject: (id) => _updateStatus(id, 'rejected')),
              _RequestList(requests: _approved, onTap: _showDetail, showActions: false),
              _RequestList(requests: _rejected, onTap: _showDetail, showActions: false),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Request list ────────────────────────────────────────────────────────────

class _RequestList extends StatelessWidget {
  final List<Map<String, dynamic>> requests;
  final void Function(Map<String, dynamic>) onTap;
  final bool showActions;
  final void Function(String)? onApprove;
  final void Function(String)? onReject;

  const _RequestList({
    required this.requests,
    required this.onTap,
    required this.showActions,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) return const EmptyState(message: 'Хүсэлт байхгүй байна');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r           = requests[i];
        final studentName = r['student']?['full_name']    ?? 'Оюутан';
        final studentCode = r['student']?['student_code'] ?? '';
        final department  = r['student']?['department']   ?? '';
        final clubName    = r['club']?['name']            ?? 'Клуб';
        final createdAt   = r['requested_at'] != null
            ? DateTime.parse(r['requested_at']).toLocal()
            : DateTime.now();
        final dateStr = '${createdAt.year}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.day.toString().padLeft(2, '0')}';

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onTap(r),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          studentName.isNotEmpty ? studentName[0] : '?',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('$studentCode • $department',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.groups_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(clubName, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                  ]),
                  if (showActions) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => onApprove?.call(r['id']),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Зөвшөөрөх'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green[700],
                              side: BorderSide(color: Colors.green.shade300),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => onReject?.call(r['id']),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Татгалзах'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red[700],
                              side: BorderSide(color: Colors.red.shade300),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Detail bottom sheet ──────────────────────────────────────────────────────

class _RequestDetailSheet extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _RequestDetailSheet({required this.request, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final studentName = request['student']?['full_name']    ?? '';
    final studentCode = request['student']?['student_code'] ?? '';
    final department  = request['student']?['department']   ?? '';
    final clubName    = request['club']?['name']            ?? '';
    final category    = request['club']?['category']        ?? '';
    final message     = request['message']                  ?? '';
    final status      = request['status']                   ?? 'pending';
    final isPending   = status == 'pending';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Хүсэлтийн дэлгэрэнгүй',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            _Row('Оюутан',          studentName),
            _Row('Оюутны код',      studentCode),
            _Row('Тэнхим',          department),
            _Row('Клуб',            clubName),
            _Row('Ангилал',         category),
            if (message.isNotEmpty) _Row('Өргөдлийн бичиг', message),
            const SizedBox(height: 20),
            if (isPending)
              Row(children: [
                Expanded(child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check),
                  label: const Text('Зөвшөөрөх'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600], foregroundColor: Colors.white),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close),
                  label: const Text('Татгалзах'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], foregroundColor: Colors.white),
                )),
              ])
            else
              Center(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: (status == 'approved' ? Colors.green : Colors.red).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status == 'approved' ? 'Зөвшөөрсөн' : 'Татгалзсан',
                  style: TextStyle(
                    color: status == 'approved' ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _Row(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 130, child: Text(k, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
      Expanded(child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
    ]),
  );
}