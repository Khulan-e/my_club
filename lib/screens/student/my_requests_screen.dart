// lib/screens/student/my_requests_screen.dart
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/theme_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/theme_and_constants.dart';

// ═══════════════════════════════════════════════════════════
// REQUEST LIST SCREEN — 4 card grid
// ═══════════════════════════════════════════════════════════
class RequestListScreen extends StatefulWidget {
  const RequestListScreen({super.key});
  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;

  // 4 type card config
  static const _typeCards = [
    _TypeCard(
      key:   'request',
      label: 'Хүсэлт',
      desc:  'Клубтай холбоотой хүсэлт гаргах',
      icon:  Icons.inbox_outlined,
      shape: _CardShape.triangle,
      bg1:   Color(0xFFB8E6C8),
      bg2:   Color(0xFF86CFA0),
      iconColor: Color(0xFF2E7D4F),
    ),
    _TypeCard(
      key:   'feedback',
      label: 'Санал',
      desc:  'Санал дэвшүүлэх, сайжруулалт',
      icon:  Icons.lightbulb_outline,
      shape: _CardShape.circle,
      bg1:   Color(0xFFFFF3B8),
      bg2:   Color(0xFFFFE57A),
      iconColor: Color(0xFF8C6D00),
    ),
    _TypeCard(
      key:   'gomdol',
      label: 'Гомдол',
      desc:  'Гомдол, маргаан шийдвэрлүүлэх',
      icon:  Icons.report_outlined,
      shape: _CardShape.hexagon,
      bg1:   Color(0xFFFFB8B8),
      bg2:   Color(0xFFFF8080),
      iconColor: Color(0xFF8B0000),
    ),
    _TypeCard(
      key:   'busad',
      label: 'Бусад',
      desc:  'Бусад асуудал, мэдэгдэл',
      icon:  Icons.star_outline_rounded,
      shape: _CardShape.star,
      bg1:   Color(0xFFB8D4FF),
      bg2:   Color(0xFF80AAFF),
      iconColor: Color(0xFF003A8C),
    ),
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final uid = supabase.auth.currentUser?.id;
      final data = await supabase
          .from('requests').select()
          .eq('sender_id', uid!)
          .order('created_at', ascending: false);
      if (mounted) setState(() {
        _requests = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openTypeCard(_TypeCard card) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ThemeProvider>(),
        child: RequestCreateScreen(typeCard: card),
      ),
    )).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Container(
      decoration: BoxDecoration(gradient: c.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: c.bgDark.withOpacity(0.97),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: c.textPrimary, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Санал хүсэлт',
              style: TextStyle(color: c.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Title
            Text('Ямар төрлийн хүсэлт гаргах вэ?',
                style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Card дарж хүсэлтээ илгээнэ үү',
                style: TextStyle(color: c.textMuted, fontSize: 13)),
            const SizedBox(height: 20),

            // 2x2 Card grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.0,
              children: _typeCards.map((card) => _buildTypeCard(card, c)).toList(),
            ),

            // My requests
            if (_requests.isNotEmpty) ...[
              const SizedBox(height: 28),
              Row(children: [
                Text('Миний хүсэлтүүд',
                    style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${_requests.length} хүсэлт',
                    style: TextStyle(color: c.textMuted, fontSize: 12)),
              ]),
              const SizedBox(height: 12),
              if (_loading)
                Center(child: CircularProgressIndicator(color: c.primary, strokeWidth: 2))
              else
                ..._requests.map((r) => _buildRequestItem(r, c)),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeCard(_TypeCard card, ThemeColors c) {
    return GestureDetector(
      onTap: () => _openTypeCard(card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [card.bg1, card.bg2],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: card.bg2.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(children: [
          // Decorative shape
          Positioned(bottom: 12, right: 12,
            child: _DecorativeShape(shape: card.shape, color: card.iconColor.withOpacity(0.15), size: 60)),
          // Content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: card.iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(card.icon, color: card.iconColor, size: 22),
                ),
                // Label
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(card.label,
                      style: TextStyle(
                          color: card.iconColor.withOpacity(0.9),
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(card.desc,
                      style: TextStyle(
                          color: card.iconColor.withOpacity(0.6),
                          fontSize: 10, height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildRequestItem(Map<String, dynamic> r, ThemeColors c) {
    final status = r['status'] as String? ?? 'pending';
    final type   = r['type']   as String? ?? 'request';
    final title  = r['title']  as String? ?? '';

    final card = _typeCards.firstWhere((t) => t.key == type, orElse: () => _typeCards[3]);

    const statusLabels = {
      'pending':     'Хүлээгдэж буй',
      'in_progress': 'Шийдвэрлэж буй',
      'resolved':    'Шийдвэрлэсэн',
      'cancelled':   'Цуцлагдсан',
    };

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<ThemeProvider>(),
          child: RequestChatScreen(request: r),
        ),
      )).then((_) => _load()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: card.iconColor.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [card.bg1, card.bg2]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(card.icon, color: card.iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(card.label, style: TextStyle(color: card.iconColor, fontSize: 11)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: card.iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(statusLabels[status] ?? status,
                style: TextStyle(color: card.iconColor, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: c.textMuted, size: 16),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// REQUEST CREATE SCREEN — Card дотор form
// ═══════════════════════════════════════════════════════════
class RequestCreateScreen extends StatefulWidget {
  final _TypeCard typeCard;
  const RequestCreateScreen({super.key, required this.typeCard});
  @override
  State<RequestCreateScreen> createState() => _RequestCreateScreenState();
}

class _RequestCreateScreenState extends State<RequestCreateScreen> {
  final _titleCtrl   = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Гарчиг болон агуулгыг бөглөнэ үү')));
      return;
    }
    setState(() => _sending = true);
    try {
      final uid = supabase.auth.currentUser?.id;
      await supabase.from('requests').insert({
        'sender_id': uid,
        'title':   _titleCtrl.text.trim(),
        'content': _contentCtrl.text.trim(),
        'type':    widget.typeCard.key,
        'status':  'pending',
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Амжилттай илгээгдлээ!'),
          backgroundColor: widget.typeCard.iconColor,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Алдаа: $e'), backgroundColor: Colors.red));
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c    = context.watch<ThemeProvider>().colors;
    final card = widget.typeCard;

    return Container(
      decoration: BoxDecoration(gradient: c.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [card.bg1, card.bg2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: card.iconColor, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(children: [
            Icon(card.icon, color: card.iconColor, size: 20),
            const SizedBox(width: 8),
            Text(card.label,
                style: TextStyle(color: card.iconColor, fontSize: 17, fontWeight: FontWeight.w700)),
          ]),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 0, 16,
              MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(children: [

            // Header card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(0, 16, 0, 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [card.bg1, card.bg2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: card.bg2.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Stack(children: [
                Positioned(right: 0, bottom: 0,
                  child: _DecorativeShape(shape: card.shape, color: card.iconColor.withOpacity(0.12), size: 80)),
                Row(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: card.iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(card.icon, color: card.iconColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(card.label,
                        style: TextStyle(color: card.iconColor, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(card.desc,
                        style: TextStyle(color: card.iconColor.withOpacity(0.7), fontSize: 12, height: 1.4)),
                  ])),
                ]),
              ]),
            ),

            // Гарчиг
            Align(alignment: Alignment.centerLeft,
              child: Text('Гарчиг', style: TextStyle(
                  color: c.textSecondary, fontSize: 13, fontWeight: FontWeight.w600))),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: card.iconColor.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _titleCtrl,
                style: TextStyle(color: c.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '${card.label}ийн гарчиг...',
                  hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  prefixIcon: Icon(card.icon, color: card.iconColor, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Агуулга
            Align(alignment: Alignment.centerLeft,
              child: Text('Агуулга', style: TextStyle(
                  color: c.textSecondary, fontSize: 13, fontWeight: FontWeight.w600))),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: card.iconColor.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _contentCtrl,
                style: TextStyle(color: c.textPrimary, fontSize: 14),
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Дэлгэрэнгүй бичнэ үү...',
                  hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Илгээх товч
            GestureDetector(
              onTap: _sending ? null : _send,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [card.bg2, card.bg1]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: card.iconColor.withOpacity(0.3),
                      blurRadius: 14, offset: const Offset(0, 5))],
                ),
                child: _sending
                    ? const Center(child: SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.send_rounded, color: card.iconColor, size: 18),
                        const SizedBox(width: 8),
                        Text('Илгээх', style: TextStyle(
                            color: card.iconColor, fontSize: 15, fontWeight: FontWeight.w700)),
                      ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// REQUEST CHAT SCREEN
// ═══════════════════════════════════════════════════════════
class RequestChatScreen extends StatefulWidget {
  final Map<String, dynamic> request;
  const RequestChatScreen({super.key, required this.request});
  @override
  State<RequestChatScreen> createState() => _RequestChatScreenState();
}

class _RequestChatScreenState extends State<RequestChatScreen> {
  final _ctrl       = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _msgs = [];
  bool _loading = true, _sending = false;
  String? _myUid;
  RealtimeChannel? _channel;

  static const _typeCards = [
    _TypeCard(key:'request', label:'Хүсэлт',  desc:'', icon:Icons.inbox_outlined,      shape:_CardShape.triangle, bg1:Color(0xFFB8E6C8), bg2:Color(0xFF86CFA0), iconColor:Color(0xFF2E7D4F)),
    _TypeCard(key:'feedback',label:'Санал',   desc:'', icon:Icons.lightbulb_outline,   shape:_CardShape.circle,   bg1:Color(0xFFFFF3B8), bg2:Color(0xFFFFE57A), iconColor:Color(0xFF8C6D00)),
    _TypeCard(key:'gomdol',  label:'Гомдол',  desc:'', icon:Icons.report_outlined,     shape:_CardShape.hexagon,  bg1:Color(0xFFFFB8B8), bg2:Color(0xFFFF8080), iconColor:Color(0xFF8B0000)),
    _TypeCard(key:'busad',   label:'Бусад',   desc:'', icon:Icons.star_outline_rounded, shape:_CardShape.star,    bg1:Color(0xFFB8D4FF), bg2:Color(0xFF80AAFF), iconColor:Color(0xFF003A8C)),
  ];

  @override
  void initState() {
    super.initState();
    _myUid = supabase.auth.currentUser?.id;
    _loadMsgs();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _ctrl.dispose(); _scrollCtrl.dispose(); _channel?.unsubscribe(); super.dispose();
  }

  Future<void> _loadMsgs() async {
    try {
      final data = await supabase.from('request_messages').select()
          .eq('request_id', widget.request['id']).order('created_at', ascending: true);
      if (mounted) setState(() { _msgs = List<Map<String, dynamic>>.from(data); _loading = false; });
      _scrollToBottom();
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  void _subscribeRealtime() {
    _channel = supabase.channel('req_${widget.request['id']}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert, schema: 'public', table: 'request_messages',
          callback: (payload) {
            final m = payload.newRecord;
            if (m['request_id'] != widget.request['id']) return;
            if (mounted) { setState(() => _msgs.add(m)); _scrollToBottom(); }
          }).subscribe();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    _ctrl.clear(); setState(() => _sending = true);
    try {
      await supabase.from('request_messages').insert({
        'request_id': widget.request['id'],
        'sender_id':  _myUid,
        'sender_role':'student',
        'content':    text,
      });
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients)
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  String _fmtTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c      = context.watch<ThemeProvider>().colors;
    final type   = widget.request['type']   as String? ?? 'request';
    final title  = widget.request['title']  as String? ?? '';
    final content= widget.request['content']as String? ?? '';
    final status = widget.request['status'] as String? ?? 'pending';
    final isResolved = status == 'resolved' || status == 'cancelled';
    final card = _typeCards.firstWhere((t) => t.key == type, orElse: () => _typeCards[3]);

    const statusLabels = {
      'pending': 'Хүлээгдэж буй', 'in_progress': 'Шийдвэрлэж буй',
      'resolved': 'Шийдвэрлэсэн', 'cancelled': 'Цуцлагдсан',
    };

    return Container(
      decoration: BoxDecoration(gradient: c.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent, elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [card.bg1, card.bg2],
                  begin: Alignment.topLeft, end: Alignment.bottomRight))),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: card.iconColor, size: 18),
            onPressed: () => Navigator.pop(context)),
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: card.iconColor, fontSize: 14, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: card.iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(statusLabels[status] ?? status,
                  style: TextStyle(color: card.iconColor, fontSize: 10, fontWeight: FontWeight.w600))),
          ]),
        ),
        body: Column(children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [card.bg1.withOpacity(0.6), card.bg2.withOpacity(0.4)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: card.iconColor.withOpacity(0.2))),
            child: Text(content, style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.5))),
          const SizedBox(height: 6),
          Divider(color: c.border.withOpacity(0.15), height: 1),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: c.primary, strokeWidth: 2))
                : _msgs.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.hourglass_empty_rounded, color: c.textMuted, size: 44),
                        const SizedBox(height: 10),
                        Text('Хариу хүлээж байна...', style: TextStyle(color: c.textMuted))]))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        itemCount: _msgs.length,
                        itemBuilder: (_, i) {
                          final m = _msgs[i];
                          final isMe = m['sender_id'] == _myUid;
                          return _buildBubble(m['content'] as String? ?? '', isMe,
                              m['sender_role'] as String? ?? '',
                              _fmtTime(m['created_at'] as String?), c, card);
                        })),
          if (!isResolved)
            Container(
              padding: EdgeInsets.only(left: 12, right: 12, top: 10,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 14),
              decoration: BoxDecoration(color: c.bgDark,
                  border: Border(top: BorderSide(color: c.border.withOpacity(0.15)))),
              child: Row(children: [
                Expanded(child: Container(
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: c.border.withOpacity(0.3))),
                  child: TextField(
                    controller: _ctrl,
                    style: TextStyle(color: c.textPrimary, fontSize: 14),
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Мессеж бичих...',
                      hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))))),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [card.bg2, card.bg1]),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: card.iconColor.withOpacity(0.3), blurRadius: 10)]),
                    child: _sending
                        ? Padding(padding: const EdgeInsets.all(12),
                            child: CircularProgressIndicator(color: card.iconColor, strokeWidth: 2))
                        : Icon(Icons.send_rounded, color: card.iconColor, size: 20))),
              ]))
          else
            Container(
              padding: const EdgeInsets.all(12), color: c.bgDark,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [card.bg1.withOpacity(0.5), card.bg2.withOpacity(0.3)]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: card.iconColor.withOpacity(0.3))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.check_circle_outline_rounded, color: card.iconColor, size: 18),
                  const SizedBox(width: 8),
                  Text(status == 'resolved' ? 'Хүсэлт шийдвэрлэгдсэн' : 'Хүсэлт цуцлагдсан',
                      style: TextStyle(color: card.iconColor, fontWeight: FontWeight.w600))]))),
        ]),
      ),
    );
  }

  Widget _buildBubble(String text, bool isMe, String role, String time,
      ThemeColors c, _TypeCard card) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(width: 30, height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [card.bg1, card.bg2]),
                shape: BoxShape.circle),
              child: Center(child: Text('🏫', style: const TextStyle(fontSize: 14)))),
            const SizedBox(width: 6),
          ],
          Flexible(child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text('🏫 Захиргаа', style: TextStyle(color: c.textMuted, fontSize: 11))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isMe ? LinearGradient(colors: [card.bg2, card.bg1]) : null,
                  color: isMe ? null : c.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18)),
                  border: isMe ? null : Border.all(color: c.border.withOpacity(0.2))),
                child: Text(text, style: TextStyle(
                    fontSize: 14, height: 1.4,
                    color: isMe ? card.iconColor : c.textPrimary))),
              const SizedBox(height: 2),
              Text(time, style: TextStyle(color: c.textMuted, fontSize: 10)),
            ])),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════
enum _CardShape { triangle, circle, hexagon, star }

class _TypeCard {
  final String key, label, desc;
  final IconData icon;
  final _CardShape shape;
  final Color bg1, bg2, iconColor;
  const _TypeCard({
    required this.key, required this.label, required this.desc,
    required this.icon, required this.shape,
    required this.bg1, required this.bg2, required this.iconColor,
  });
}

// ═══════════════════════════════════════════════════════════
// DECORATIVE SHAPE WIDGET
// ═══════════════════════════════════════════════════════════
class _DecorativeShape extends StatelessWidget {
  final _CardShape shape;
  final Color color;
  final double size;
  const _DecorativeShape({required this.shape, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ShapePainter(shape: shape, color: color),
    );
  }
}

class _ShapePainter extends CustomPainter {
  final _CardShape shape;
  final Color color;
  const _ShapePainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final cx = size.width / 2, cy = size.height / 2;
    switch (shape) {
      case _CardShape.triangle:
        final path = Path()
          ..moveTo(cx, 0)..lineTo(size.width, size.height)
          ..lineTo(0, size.height)..close();
        canvas.drawPath(path, paint);
        break;
      case _CardShape.circle:
        canvas.drawCircle(Offset(cx, cy), size.width / 2, paint);
        break;
      case _CardShape.hexagon:
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = (i * 60 - 30) * 3.14159 / 180;
          final x = cx + cx * 0.9 * cos(angle);
          final y = cy + cy * 0.9 * sin(angle);
          i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
      case _CardShape.star:
        final path = Path();
        for (int i = 0; i < 10; i++) {
          final angle = (i * 36 - 90) * 3.14159 / 180;
          final r = i.isEven ? cx * 0.9 : cx * 0.45;
          final x = cx + r * cos(angle);
          final y = cy + r * sin(angle);
          i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
    }
  }

  double cos(double angle) => _cos(angle);
  double sin(double angle) => _sin(angle);

  double _cos(double x) {
    double result = 1, term = 1;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / (2 * i * (2 * i - 1));
      result += term;
    }
    return result;
  }

  double _sin(double x) {
    double result = x, term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i + 1) * (2 * i));
      result += term;
    }
    return result;
  }

  @override
  bool shouldRepaint(_ShapePainter old) => old.shape != shape || old.color != color;
}