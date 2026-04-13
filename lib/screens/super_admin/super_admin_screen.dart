// lib/screens/super_admin/super_admin_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/theme_and_constants.dart';
import '../../widgets/common_widgets.dart';

// ✅ null-safe helper: нэрний эхний үсэг авах
String _initial(dynamic name) {
  final s = (name ?? '').toString();
  return s.isNotEmpty ? s[0] : '?';
}

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});
  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  int _selectedIndex = 0;

  void _goToTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardTab(onTabChange: _goToTab),
      const _ManageClubsTab(),
      const _ManageUsersTab(),
      const _RequestsTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Супер админ'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Гарах',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Клубүүд',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Хэрэглэгчид',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Хүсэлтүүд',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Dashboard tab
// ─────────────────────────────────────────
class _DashboardTab extends StatefulWidget {
  final void Function(int) onTabChange;
  const _DashboardTab({required this.onTabChange});
  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final _adminService = AdminService();
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _topClubs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _adminService.getDashboardStats(),
        _adminService.getTopClubs(),
      ]);
      if (mounted) {
        setState(() {
          _stats    = results[0] as Map<String, dynamic>;
          _topClubs = results[1] as List<Map<String, dynamic>>;
          _loading  = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_stats == null) {
      return const EmptyState(message: 'Статистик ачаалж чадсангүй', icon: Icons.error_outline);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                _statCard('Нийт клуб', '${_stats!['total_clubs'] ?? 0}', Icons.groups_rounded, AppColors.primary, () => widget.onTabChange(1)),
                _statCard('Нийт оюутан', '${_stats!['total_students'] ?? 0}', Icons.people_rounded, AppColors.teal, () => widget.onTabChange(2)),
                _statCard('Хүлээгдэж буй', '${_stats!['pending_requests'] ?? 0}', Icons.pending_rounded, AppColors.amber, () => widget.onTabChange(3)),
                _statCard('Нийт цаг', '${_stats!['total_volunteer_hours'] ?? 0}', Icons.schedule_rounded, AppColors.coral, null),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Идэвхтэй клубүүд', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 10),
            ..._topClubs.take(5).map((c) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Text(_initial(c['name']),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
                title: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('${c['member_count'] ?? 0} гишүүн  ·  ${c['total_hours_given'] ?? 0} цаг',
                  style: const TextStyle(fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: AppColors.amber),
                    const SizedBox(width: 3),
                    Text(((c['avg_rating'] ?? 0) as num).toStringAsFixed(1),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 22),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color.withOpacity(0.4)),
              ],
            ),
            const Spacer(),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────
// Клуб удирдах tab
// ─────────────────────────────────────────
class _ManageClubsTab extends StatefulWidget {
  const _ManageClubsTab();
  @override
  State<_ManageClubsTab> createState() => _ManageClubsTabState();
}

class _ManageClubsTabState extends State<_ManageClubsTab> {
  final _clubService = ClubService();
  final _adminService = AdminService();
  List<Map<String, dynamic>> _clubs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final clubs = await _clubService.getClubs();
    if (mounted) setState(() { _clubs = clubs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading ? const LoadingView() : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _clubs.length,
          itemBuilder: (_, i) {
            final c = _clubs[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.groups_rounded, color: AppColors.primary, size: 20),
                ),
                title: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Row(children: [
                  CategoryBadge(category: c['category']),
                  const SizedBox(width: 8),
                  Text('${c['member_count'] ?? 0} гишүүн', style: const TextStyle(fontSize: 11)),
                ]),
                trailing: PopupMenuButton<String>(
                  itemBuilder: (_) => <PopupMenuEntry<String>>[
                    PopupMenuItem(
                      child: const ListTile(
                        leading: Icon(Icons.people_outline),
                        title: Text('Гишүүд'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onTap: () async {
                        final members = await _adminService.getClubMembers(c['id']);
                        if (context.mounted) _showMembers(context, c['name'] ?? '', members);
                      },
                    ),
                    PopupMenuItem(
                      child: const ListTile(
                        leading: Icon(Icons.person_add_outlined),
                        title: Text('Тэргүүн томилох'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onTap: () => _showAssignAdminDialog(context, c['id'], c['name'] ?? ''),
                    ),
                    PopupMenuItem(
                      child: const ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text('Устгах', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Клуб устгах'),
                            content: Text('${c['name']} клубыг устгах уу?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Үгүй')),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Тийм'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _clubService.deleteClub(c['id']);
                          _load();
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClubDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Клуб нэмэх'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showMembers(BuildContext context, String clubName, List<Map<String, dynamic>> members) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, ctrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('$clubName — гишүүд (${members.length})',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            Expanded(
              child: members.isEmpty
                  ? const Center(child: Text('Гишүүн байхгүй', style: TextStyle(color: AppColors.textMuted)))
                  : ListView.builder(
                      controller: ctrl,
                      itemCount: members.length,
                      itemBuilder: (_, i) {
                        final u = members[i]['users'] as Map<String, dynamic>? ?? {};
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            child: Text(_initial(u['full_name']),
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                          ),
                          title: Text(u['full_name'] ?? 'Нэргүй'),
                          subtitle: Text('${u['student_code'] ?? ''} · ${u['email'] ?? ''}',
                            style: const TextStyle(fontSize: 12)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignAdminDialog(BuildContext context, String clubId, String clubName) async {
    final adminService = AdminService();
    final users = await adminService.getUsers();

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) {
        final searchCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setS) {
            final filtered = users.where((u) {
              final q = searchCtrl.text.toLowerCase();
              if (q.isEmpty) return true;
              return (u['full_name'] ?? '').toLowerCase().contains(q) ||
                     (u['student_code'] ?? '').toLowerCase().contains(q) ||
                     (u['email'] ?? '').toLowerCase().contains(q);
            }).toList();

            return AlertDialog(
              title: Text('$clubName — тэргүүн томилох'),
              content: SizedBox(
                width: 400,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      controller: searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Нэр, код, и-мэйлээр хайх...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        isDense: true,
                      ),
                      onChanged: (_) => setS(() {}),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final u = filtered[i];
                          final role = UserRole.fromDb(u['role']);
                          final isCurrentAdmin = u['managed_club_id'] == clubId && role == UserRole.clubAdmin;
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: isCurrentAdmin ? AppColors.tealLight : AppColors.primaryLight,
                              child: Text(_initial(u['full_name']),
                                style: TextStyle(
                                  color: isCurrentAdmin ? AppColors.teal : AppColors.primary,
                                  fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                            title: Text(u['full_name'] ?? 'Нэргүй', style: const TextStyle(fontSize: 13)),
                            subtitle: Text('${u['student_code'] ?? ''} · ${role.label}',
                              style: const TextStyle(fontSize: 11)),
                            trailing: isCurrentAdmin
                                ? const Chip(label: Text('Тэргүүн', style: TextStyle(fontSize: 10)), backgroundColor: AppColors.tealLight)
                                : TextButton(
                                    onPressed: () async {
                                      await adminService.assignClubAdmin(u['id'], clubId);
                                      if (ctx.mounted) {
                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${u['full_name']} тэргүүнээр томилогдлоо'),
                                            backgroundColor: AppColors.teal,
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text('Томилох', style: TextStyle(fontSize: 12)),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Хаах')),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddClubDialog(BuildContext context) {
    final nameCtrl   = TextEditingController();
    final descCtrl   = TextEditingController();
    final emailCtrl  = TextEditingController();
    final phoneCtrl  = TextEditingController();
    final instrCtrl  = TextEditingController();
    String cat = 'professional';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Клуб нэмэх'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(controller: nameCtrl, label: 'Клубын нэр'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: cat,
                  decoration: const InputDecoration(labelText: 'Ангилал'),
                  items: const [
                    DropdownMenuItem(value: 'professional', child: Text('Мэргэжлийн')),
                    DropdownMenuItem(value: 'hobby',        child: Text('Сонирхлын')),
                    DropdownMenuItem(value: 'art',          child: Text('Урлагийн')),
                  ],
                  onChanged: (v) => setS(() => cat = v!),
                ),
                const SizedBox(height: 10),
                AppTextField(controller: descCtrl, label: 'Тайлбар', maxLines: 3),
                const SizedBox(height: 10),
                AppTextField(controller: emailCtrl, label: 'И-мэйл', keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 10),
                AppTextField(controller: phoneCtrl, label: 'Утас', keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                AppTextField(controller: instrCtrl, label: 'Элсэх заавар', maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Цуцлах')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                await ClubService().createClub({
                  'name':            nameCtrl.text.trim(),
                  'category':        cat,
                  'description':     descCtrl.text.trim(),
                  'email':           emailCtrl.text.trim(),
                  'phone':           phoneCtrl.text.trim(),
                  'join_instruction': instrCtrl.text.trim(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              child: const Text('Нэмэх'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Хэрэглэгч удирдах tab
// ─────────────────────────────────────────
class _ManageUsersTab extends StatefulWidget {
  const _ManageUsersTab();
  @override
  State<_ManageUsersTab> createState() => _ManageUsersTabState();
}

class _ManageUsersTabState extends State<_ManageUsersTab> {
  final _adminService = AdminService();
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load({String? search}) async {
    setState(() => _loading = true);
    final users = await _adminService.getUsers(search: search);
    if (mounted) setState(() { _users = users; _loading = false; });
  }

  void _showRoleDialog(Map<String, dynamic> user) {
    final currentRole = UserRole.fromDb(user['role']);
    UserRole selectedRole = currentRole;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(user['full_name'] ?? 'Хэрэглэгч'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('И-мэйл: ${user['email'] ?? ''}',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
              Text('Код: ${user['student_code'] ?? ''}',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 16),
              const Text('Role сонгох:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...UserRole.values.map((role) => RadioListTile<UserRole>(
                title: Text(role.label),
                subtitle: Text(_roleDescription(role), style: const TextStyle(fontSize: 11)),
                value: role,
                groupValue: selectedRole,
                dense: true,
                onChanged: (v) => setS(() => selectedRole = v!),
              )),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Цуцлах')),
            ElevatedButton(
              onPressed: selectedRole == currentRole ? null : () async {
                if (selectedRole == UserRole.clubAdmin) {
                  Navigator.pop(ctx);
                  _showSelectClubForAdmin(user);
                } else {
                  await _adminService.setUserRole(user['id'], selectedRole.toDb());
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load(search: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${user['full_name']} → ${selectedRole.label}'),
                        backgroundColor: AppColors.teal,
                      ),
                    );
                  }
                }
              },
              child: const Text('Хадгалах'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSelectClubForAdmin(Map<String, dynamic> user) async {
    final clubs = await ClubService().getClubs();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${user['full_name']} — клуб сонгох'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: ListView.builder(
            itemCount: clubs.length,
            itemBuilder: (ctx, i) {
              final c = clubs[i];
              return ListTile(
                dense: true,
                title: Text(c['name'] ?? '', style: const TextStyle(fontSize: 13)),
                subtitle: Text(c['category'] ?? '', style: const TextStyle(fontSize: 11)),
                onTap: () async {
                  await _adminService.assignClubAdmin(user['id'], c['id']);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load(search: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${user['full_name']} → ${c['name']} тэргүүн'),
                        backgroundColor: AppColors.teal,
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Цуцлах')),
        ],
      ),
    );
  }

  String _roleDescription(UserRole role) {
    switch (role) {
      case UserRole.student:    return 'Энгийн оюутан хэрэглэгч';
      case UserRole.clubAdmin:  return 'Тодорхой клубын тэргүүн, удирдлага';
      case UserRole.superAdmin: return 'Бүх системийн удирдлага';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Нэр, код, и-мэйлээр хайх...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _load();
                      })
                  : null,
            ),
            onChanged: (v) => _load(search: v.isNotEmpty ? v : null),
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _users.isEmpty
                  ? const EmptyState(message: 'Хэрэглэгч олдсонгүй', icon: Icons.people_outline)
                  : RefreshIndicator(
                      onRefresh: () => _load(search: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _users.length,
                        itemBuilder: (_, i) {
                          final u = _users[i];
                          final role = UserRole.fromDb(u['role']);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _roleBgColor(role),
                                child: Text(_initial(u['full_name']),
                                  style: TextStyle(
                                    color: _roleFgColor(role),
                                    fontWeight: FontWeight.w600)),
                              ),
                              title: Text(u['full_name'] ?? 'Нэргүй',
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                              subtitle: Text(
                                '${u['student_code'] ?? ''} · ${u['email'] ?? ''}',
                                style: const TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _roleBgColor(role),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(role.label,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                    color: _roleFgColor(role))),
                              ),
                              onTap: () => _showRoleDialog(u),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Color _roleBgColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin: return AppColors.coralLight;
      case UserRole.clubAdmin:  return AppColors.tealLight;
      case UserRole.student:    return AppColors.primaryLight;
    }
  }

  Color _roleFgColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin: return AppColors.coral;
      case UserRole.clubAdmin:  return AppColors.teal;
      case UserRole.student:    return AppColors.primary;
    }
  }
}

// ─────────────────────────────────────────
// Хүсэлтүүд tab
// ─────────────────────────────────────────
class _RequestsTab extends StatefulWidget {
  const _RequestsTab();
  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  final _reqService = JoinRequestService();
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final reqs = await _reqService.getAllPendingRequests();
    if (mounted) setState(() { _requests = reqs; _loading = false; });
  }

  Future<void> _approve(String id) async {
    await _reqService.approveRequest(id);
    _load();
  }

  Future<void> _reject(String id) async {
    await _reqService.rejectRequest(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return _loading ? const LoadingView() : RefreshIndicator(
      onRefresh: _load,
      child: _requests.isEmpty
          ? const EmptyState(message: 'Хүлээгдэж буй хүсэлт байхгүй', icon: Icons.check_circle_outline)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _requests.length,
              itemBuilder: (_, i) {
                final r = _requests[i];
                final user = r['users'] as Map<String, dynamic>? ?? {};
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primaryLight,
                              child: Text(_initial(user['full_name']),
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user['full_name'] ?? 'Нэргүй', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('${user['student_code'] ?? ''}  ·  ${r['clubs']?['name'] ?? ''}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (r['message'] != null && (r['message'] as String).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(r['message'],
                              style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _reject(r['id']),
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('Татгалзах'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _approve(r['id']),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Батлах'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}