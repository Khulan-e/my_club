// lib/screens/student/chat_tab_screen.dart
// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show FontFeature;
import 'package:audioplayers/audioplayers.dart' hide AndroidAudioMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme_and_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/supabase_service.dart';

// ─────────────────────────────────────────────────────────────
// Avatar icon list — my_profile_screen.dart-тай яг ижил байх ёстой
// ─────────────────────────────────────────────────────────────
const List<IconData> _kAvatarIcons = [
  Icons.person_rounded,
  Icons.face_rounded,
  Icons.sentiment_very_satisfied_rounded,
  Icons.school_rounded,
  Icons.star_rounded,
  Icons.rocket_launch_rounded,
  Icons.auto_awesome_rounded,
  Icons.psychology_rounded,
  Icons.eco_rounded,
  Icons.local_fire_department_rounded,
  Icons.diamond_rounded,
  Icons.bolt_rounded,
  Icons.palette_rounded,
  Icons.sports_esports_rounded,
  Icons.music_note_rounded,
  Icons.sports_basketball_rounded,
];

int? _avatarIconIndex(String? avatarUrl) {
  if (avatarUrl == null || !avatarUrl.startsWith('icon:')) return null;
  final idx = int.tryParse(avatarUrl.replaceFirst('icon:', '')) ?? 0;
  return idx.clamp(0, _kAvatarIcons.length - 1);
}

/// Хэрэглэгчийн avatar-ыг 3 төрлөөр харуулна:
///  1) `icon:N` форматтай бол сонгосон icon
///  2) `https://...` бол upload хийсэн зураг
///  3) Үгүй бол initials
///
/// Гадна талын тойрог/clip-ийг дуудагч хариуцна — энэ зөвхөн дотоод
/// content-ийг буцаана.
Widget buildUserAvatar({
  required String? avatarUrl,
  required String initials,
  required Color fallbackColor,
  required double size,
  ThemeColors? themeColors,
}) {
  // 1) Icon: format
  final iconIdx = _avatarIconIndex(avatarUrl);
  if (iconIdx != null) {
    final palette = themeColors != null
        ? <Color>[themeColors.primary, themeColors.teal, themeColors.accent, themeColors.coral]
        : <Color>[fallbackColor];
    final iconColor = palette[iconIdx % palette.length];
    return Container(
      width: size, height: size,
      color: iconColor.withOpacity(0.18),
      alignment: Alignment.center,
      child: Icon(_kAvatarIcons[iconIdx], color: iconColor, size: size * 0.55),
    );
  }
  // 2) URL зураг
  if (avatarUrl != null && avatarUrl.isNotEmpty) {
    return Image.network(
      avatarUrl,
      fit: BoxFit.cover,
      width: size, height: size,
      errorBuilder: (_, __, ___) => _initialsBox(initials, fallbackColor, size),
    );
  }
  // 3) Initials
  return _initialsBox(initials, fallbackColor, size);
}

Widget _initialsBox(String initials, Color color, double size) => Container(
  width: size, height: size,
  color: color, alignment: Alignment.center,
  child: Text(
    initials,
    style: TextStyle(color: Colors.white, fontSize: size * 0.4, fontWeight: FontWeight.bold),
  ),
);

// ─────────────────────────────────────────────────────────────
// RINGTONE GENERATOR — WAV-ыг program-аар үүсгэж тоглуулна.
// Олон сине нэгтгэсэн "bell"-маягийн дуу. Сүлжээгүй ч ажиллана.
// ─────────────────────────────────────────────────────────────
class _RingtoneNote {
  final List<double> freqs;     // Зэрэгцэн дуугарах frequency-ууд (chord/harmonic)
  final int durationMs;
  final int silenceMs;
  final double envelopeDecay;   // 0=тогтмол, 1=хурдан унтрах ("bell"-шиг)
  const _RingtoneNote({
    required this.freqs,
    required this.durationMs,
    this.silenceMs = 0,
    this.envelopeDecay = 0.6,
  });
}

class _RingtoneEngine {
  AudioPlayer? _player;
  Timer? _loopTimer;
  String? _filePath;
  Duration _interval = const Duration(seconds: 2);

  /// Bell-маягийн дуу (FM/additive synthesis) WAV үүсгэнэ.
  /// Үндсэн frequency дээр ёс заншлын bell harmonic stack нэмэгдэнэ:
  ///   1.0x   (fundamental)
  ///   2.0x   (octave) — sus
  ///   2.4x   (minor 3rd above 8th)
  ///   3.0x   (perfect 5th above 8th)
  ///   4.5x   (high overtone)
  /// Эдгээрийн харьцангуй амплитуд бодит хонхтой ойролцоо.
  /// 16-bit PCM, mono, 22.05kHz (илүү ойлгомжтой дуу).
  static Uint8List buildWav(List<_RingtoneNote> notes) {
    const sampleRate = 22050;
    // Хонхны harmonic-ууд (frequency multiplier, amplitude)
    const bellHarmonics = [
      [1.0,  1.00], // fundamental
      [2.0,  0.55], // 1st overtone (octave)
      [2.4,  0.30], // 2nd overtone — bell metal-ийн өвөрмөц өнгө
      [3.0,  0.20], // 3rd overtone
      [4.5,  0.10], // өндөр sparkle
    ];

    final allPcm = BytesBuilder();
    for (final n in notes) {
      final samples = (sampleRate * n.durationMs / 1000).round();
      final pcm = Int16List(samples);
      final dur = n.durationMs / 1000;
      for (int i = 0; i < samples; i++) {
        final t = i / sampleRate;
        // Хатуу attack (3ms) — strike-ийн транзиент
        const attack = 0.003;
        double env;
        if (t < attack) {
          env = t / attack;
        } else {
          final progress = (t - attack) / (dur - attack);
          env = math.exp(-progress * n.envelopeDecay * 4).clamp(0.0, 1.0);
        }
        // Bell synthesis: үндсэн frequency бүрд харьцангуй harmonic нэмнэ.
        // Дээд harmonic-ууд илүү хурдан унтрана (бодит хонхтой ижил).
        double sample = 0;
        double weightSum = 0;
        for (final f0 in n.freqs) {
          for (final h in bellHarmonics) {
            final mult = h[0];
            final amp  = h[1];
            // Дээд harmonic илүү хурдан унтрана
            final harmonicEnv = math.pow(env, 1.0 + (mult - 1.0) * 0.4).toDouble();
            sample    += math.sin(2 * math.pi * f0 * mult * t) * amp * harmonicEnv;
            weightSum += amp;
          }
        }
        sample = sample / weightSum * 0.85; // [-0.85, 0.85] normalize
        final value = (sample * 32000).round().clamp(-32767, 32767);
        pcm[i] = value;
      }
      allPcm.add(pcm.buffer.asUint8List());
      if (n.silenceMs > 0) {
        final silenceSamples = (sampleRate * n.silenceMs / 1000).round();
        allPcm.add(Uint8List(silenceSamples * 2));
      }
    }
    final dataBytes = allPcm.toBytes();

    final wav = BytesBuilder();
    void writeStr(String s) => wav.add(s.codeUnits);
    void writeU32(int n) => wav.add([n & 0xff, (n >> 8) & 0xff, (n >> 16) & 0xff, (n >> 24) & 0xff]);
    void writeU16(int n) => wav.add([n & 0xff, (n >> 8) & 0xff]);
    writeStr('RIFF');
    writeU32(36 + dataBytes.length);
    writeStr('WAVE');
    writeStr('fmt ');
    writeU32(16);
    writeU16(1);              // PCM
    writeU16(1);              // mono
    writeU32(sampleRate);
    writeU32(sampleRate * 2);
    writeU16(2);
    writeU16(16);
    writeStr('data');
    writeU32(dataBytes.length);
    wav.add(dataBytes);
    return wav.toBytes();
  }

  /// Ирж буй дуудлагын хонх — Messenger маягийн уянгалаг "DING-DONG"
  /// Note: G5 (783.99Hz) → E5 (659.25Hz) → C5 (523.25Hz) → A4 (440Hz)
  /// Major-key descending pattern, bell-маягийн harmonic-той.
  static Uint8List incomingRingWav() => buildWav(const [
    // Эхний "Ding-Dong"
    _RingtoneNote(freqs: [783.99], durationMs: 350, silenceMs: 80,  envelopeDecay: 0.65), // G5
    _RingtoneNote(freqs: [659.25], durationMs: 480, silenceMs: 350, envelopeDecay: 0.55), // E5
    // Хоёр дахь "Ding-Dong" (бага октавт)
    _RingtoneNote(freqs: [659.25], durationMs: 350, silenceMs: 80,  envelopeDecay: 0.65), // E5
    _RingtoneNote(freqs: [523.25], durationMs: 700, silenceMs: 0,   envelopeDecay: 0.45), // C5 (long ring)
  ]);

  /// Caller-ийн дуудаж буй дуу (online) — Messenger-маягийн "ding-ding"
  /// Богино, динамик. 1.5 сек тутамд давтана.
  static Uint8List callerRingWav() => buildWav(const [
    _RingtoneNote(freqs: [523.25], durationMs: 280, silenceMs: 80,  envelopeDecay: 0.55), // C5
    _RingtoneNote(freqs: [659.25], durationMs: 380, silenceMs: 0,   envelopeDecay: 0.50), // E5
  ]);

  /// Caller-ийн дуудаж буй дуу (offline) — уламжлалт телефоны удаан
  /// "BRR... BRR..." pulse. Илүү урт wav, давталт хооронд урт чимээгүй.
  /// Хэрэглэгч utas авахгүй гэж мэдрэхээр.
  static Uint8List callerOfflineRingWav() => buildWav(const [
    // Хоёр давхар pulse, удаан унтрах envelope
    _RingtoneNote(freqs: [440.0], durationMs: 300, silenceMs: 100, envelopeDecay: 0.45),
    _RingtoneNote(freqs: [440.0], durationMs: 300, silenceMs: 100, envelopeDecay: 0.45),
    _RingtoneNote(freqs: [440.0], durationMs: 600, silenceMs: 0,   envelopeDecay: 0.30),
  ]);

  Future<void> startLoop({
    required Uint8List wav,
    required Duration interval,
  }) async {
    await stop();
    _interval = interval;
    // BytesSource зарим Android version дээр найдваргүй учир temp file ашиглана
    try {
      final tmpDir = await getTemporaryDirectory();
      final f = File('${tmpDir.path}/ring_${DateTime.now().millisecondsSinceEpoch}.wav');
      await f.writeAsBytes(wav, flush: true);
      _filePath = f.path;
    } catch (e) {
      debugPrint('Ring temp file бичих алдаа: $e');
    }
    _player = AudioPlayer();
    try {
      await _player!.setReleaseMode(ReleaseMode.stop);
      await _player!.setVolume(1.0);
      // MEDIA volume-ийг ашиглана — DnD горимд ч сонсогдоно, хэрэглэгчийн volume-ээс хамаарна
      try {
        await _player!.setAudioContext(AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType:   AndroidUsageType.media,
            audioFocus:  AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
        ));
      } catch (e) { debugPrint('Audio context алдаа: $e'); }
    } catch (e) { debugPrint('Ring player setup алдаа: $e'); }

    await _playOnce();
    _loopTimer = Timer.periodic(_interval, (_) => _playOnce());
  }

  Future<void> _playOnce() async {
    final p = _player;
    if (p == null) return;
    try {
      if (_filePath != null) {
        await p.play(DeviceFileSource(_filePath!));
      }
    } catch (e) { debugPrint('Ring play алдаа: $e'); }
  }

  Future<void> stop() async {
    _loopTimer?.cancel();
    _loopTimer = null;
    try { await _player?.stop(); } catch (_) {}
    try { await _player?.dispose(); } catch (_) {}
    _player = null;
    if (_filePath != null) {
      try { await File(_filePath!).delete(); } catch (_) {}
      _filePath = null;
    }
  }
}

// ═══════════════════════════════════════════════════════════
// ROUTE
// ═══════════════════════════════════════════════════════════
class ChatTabRoute extends PageRouteBuilder {
  ChatTabRoute()
      : super(
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (_, __, ___) => const ChatTabScreen(),
          transitionsBuilder: (_, animation, __, child) {
            final tween = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        );
}

// ═══════════════════════════════════════════════════════════
// CHAT TAB SCREEN — global incoming call listener
// ═══════════════════════════════════════════════════════════
class ChatTabScreen extends StatefulWidget {
  const ChatTabScreen({super.key});
  @override State<ChatTabScreen> createState() => _ChatTabScreenState();
}

class _ChatTabScreenState extends State<ChatTabScreen> {
  // Дуудлагын listener одоо global болсон (IncomingCallListener) тул эндээс хассан.

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.bgDark,
        appBar: AppBar(
          backgroundColor: c.bgDark, elevation: 0,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border: Border.all(color: Colors.white.withOpacity(0.12))),
              child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 16),
            ),
          ),
          title: Text('Чат', style: TextStyle(color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        body: const _MessengerTab(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MESSENGER TAB — AI card + conversations
// ═══════════════════════════════════════════════════════════
class _MessengerTab extends StatefulWidget {
  const _MessengerTab();
  @override State<_MessengerTab> createState() => _MessengerTabState();
}

class _MessengerTabState extends State<_MessengerTab> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _searchingUsers = false, _showSearch = false;
  List<Map<String, dynamic>> _convs = [], _onlineMembers = [];
  bool _loading = true;
  RealtimeChannel? _channel, _presenceChannel;
  final Set<String> _onlineIds = {};

  Timer? _convListPollTimer;

  @override void initState() { super.initState(); _load(); _subscribeRealtime(); _subscribePresence(); }
  @override void dispose() {
    _searchCtrl.dispose();
    _channel?.unsubscribe();
    _presenceChannel?.unsubscribe();
    _convListPollTimer?.cancel();
    super.dispose();
  }

  void _subscribePresence() {
    final uid = supabase.auth.currentUser?.id; if (uid == null) return;
    _presenceChannel = supabase.channel('online_users')
      ..onPresenceSync((_) {
        final state = _presenceChannel?.presenceState(); final ids = <String>{};
        if (state != null) for (final p in state) { try { final id = ((p as dynamic).payload as Map?)?['user_id'] as String?; if (id != null) ids.add(id); } catch (_) {} }
        if (mounted) setState(() => _onlineIds..clear()..addAll(ids));
      })
      ..subscribe((status, _) async { if (status == RealtimeSubscribeStatus.subscribed) await _presenceChannel?.track({'user_id': uid}); });
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().length < 2) { setState(() { _searchResults = []; _searchingUsers = false; }); return; }
    setState(() => _searchingUsers = true);
    try {
      final uid = supabase.auth.currentUser?.id;
      final res = await supabase.from('users').select('id, full_name, email, student_code, avatar_url')
          .or('full_name.ilike.%$query%,student_code.ilike.%$query%').neq('id', uid ?? '').limit(15);
      if (mounted) setState(() { _searchResults = List<Map<String, dynamic>>.from(res); _searchingUsers = false; });
    } catch (_) { if (mounted) setState(() => _searchingUsers = false); }
  }

  Future<void> _load() async {
    try {
      final uid = supabase.auth.currentUser?.id; if (uid == null) return;

      // Parallel: club conversations + online members
      await Future.wait([_ensureClubConversations(uid), _loadOnlineMembers(uid)]);

      final myConvIds = await supabase
          .from('conversation_members')
          .select('conversation_id')
          .eq('user_id', uid);
      final ids = (myConvIds as List).map((e) => e['conversation_id'] as String).toList();
      if (ids.isEmpty) { if (mounted) setState(() => _loading = false); return; }

      // Load each conv sequentially (safe color index), but batch sub-queries in parallel
      final convData = <Map<String, dynamic>>[];
      for (int i = 0; i < ids.length; i++) {
        final conv = await _loadSingleConv(ids[i], uid, i);
        if (conv != null) convData.add(conv);
      }
      convData.sort((a, b) => (b['lastTime'] as String? ?? '').compareTo(a['lastTime'] as String? ?? ''));
      if (mounted) setState(() { _convs = convData; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<Map<String, dynamic>?> _loadSingleConv(String convId, String uid, int index) async {
    try {
      final results = await Future.wait([
        supabase.from('conversations').select().eq('id', convId).single(),
        supabase.from('messages').select('content, created_at').eq('conversation_id', convId)
            .order('created_at', ascending: false).limit(1).maybeSingle(),
        supabase.from('conversation_members').select('last_seen_at')
            .eq('conversation_id', convId).eq('user_id', uid).single(),
      ]);
      final conv       = results[0] as Map<String, dynamic>;
      final lastMsg    = results[1] as Map<String, dynamic>?;
      final myLastSeen = results[2] as Map<String, dynamic>;

      String name = '', initials = '';
      bool isGroup = conv['type'] == 'group';
      String? otherUserId;
      String? avatarUrl;

      // ── unread + color — эхэнд declare ──────────────────
      int unread = 0;
      if (myLastSeen['last_seen_at'] != null) {
        final ur = await supabase.from('messages').select('id')
            .eq('conversation_id', convId).neq('sender_id', uid)
            .gt('created_at', myLastSeen['last_seen_at']);
        unread = (ur as List).length;
      }
      const acs = ['#E8547A', '#4F8EF7', '#2DB87A', '#7C5CBF', '#F5A623'];
      final color = acs[index % acs.length];

      if (!isGroup) {
        final om = await supabase.from('conversation_members')
            .select('user_id').eq('conversation_id', convId).neq('user_id', uid).maybeSingle();
        if (om != null) {
          otherUserId = om['user_id'] as String;
          final ui = await supabase.from('users')
              .select('full_name, avatar_url').eq('id', otherUserId).single();
          name = ui['full_name'] ?? 'Хэрэглэгч';
          initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
          final av = ui['avatar_url'] as String?;
          avatarUrl = (av != null && av.isNotEmpty) ? av : null;
        }
      } else {
        if (conv['club_id'] != null) {
          final club = await supabase.from('clubs').select('name')
              .eq('id', conv['club_id']).single();
          name = club['name'] ?? 'Клуб';
          initials = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name[0].toUpperCase();
        }
      }

      return {
        'id': convId, 'name': name, 'initials': initials,
        'color': color,
        'lastMsg': lastMsg?['content'] ?? '',
        'lastTime': lastMsg?['created_at'] ?? conv['created_at'],
        'unread': unread, 'isGroup': isGroup,
        'otherUserId': otherUserId,
        'avatar_url': avatarUrl,
      };
    } catch (_) { return null; }
  }

  Future<void> _ensureClubConversations(String uid) async {
    final memberships = await supabase.from('club_memberships').select('club_id').eq('user_id', uid).eq('status', 'approved');
    for (final m in (memberships as List)) {
      final clubId = m['club_id'] as String;
      final existing = await supabase.from('conversations').select('id').eq('club_id', clubId).eq('type', 'group').maybeSingle();
      if (existing == null) {
        final nc = await supabase.from('conversations').insert({'type': 'group', 'club_id': clubId}).select().single();
        final members = await supabase.from('club_memberships').select('user_id').eq('club_id', clubId).eq('status', 'approved');
        final inserts = (members as List).map((cm) => {'conversation_id': nc['id'], 'user_id': cm['user_id']}).toList();
        if (inserts.isNotEmpty) await supabase.from('conversation_members').upsert(inserts);
      } else { await supabase.from('conversation_members').upsert({'conversation_id': existing['id'], 'user_id': uid}); }
    }
  }

  Future<void> _loadOnlineMembers(String uid) async {
    final memberships = await supabase.from('club_memberships').select('club_id').eq('user_id', uid).eq('status', 'approved');
    final clubIds = (memberships as List).map((m) => m['club_id'] as String).toList();
    if (clubIds.isEmpty) return;
    final members = await supabase.from('club_memberships')
        .select('user_id, users(full_name, avatar_url)')
        .inFilter('club_id', clubIds).eq('status', 'approved').neq('user_id', uid).limit(20);
    final acs = ['#E8547A', '#4F8EF7', '#2DB87A', '#7C5CBF', '#F5A623'];
    final seen = <String>{}; final result = <Map<String, dynamic>>[];
    for (final m in (members as List)) {
      final userId = m['user_id'] as String; if (seen.contains(userId)) continue; seen.add(userId);
      final u = m['users'] as Map<String, dynamic>?;
      final name = u?['full_name'] as String? ?? 'Хэрэглэгч';
      final avatarUrl = u?['avatar_url'] as String?;
      result.add({
        'id': userId,
        'name': name.split(' ').first,
        'initials': name.isNotEmpty ? name[0].toUpperCase() : '?',
        'color': acs[result.length % acs.length],
        'avatar_url': (avatarUrl != null && avatarUrl.isNotEmpty) ? avatarUrl : null,
      });
    }
    if (mounted) setState(() => _onlineMembers = result);
  }

  void _subscribeRealtime() {
    _channel = supabase.channel('messenger_tab_v2')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public', table: 'messages',
        callback: (payload) async {
          final nm = payload.newRecord;
          final convId = nm['conversation_id'] as String?;
          if (convId == null) return;
          _applyMessageToConvList(convId, nm);
        })
      .subscribe((status, err) => debugPrint('[chat-list] realtime status=$status err=$err'));

    // Polling fallback — realtime delivery бүрэн байх атал, мөн зэрэгцээ ажиллуулна.
    // 4 секунд тутамд бүх conversations-ийн лост message-ийн төлвийг шинэчилнэ.
    _convListPollTimer?.cancel();
    _convListPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _load();
    });
  }

  void _applyMessageToConvList(String convId, Map<String, dynamic> nm) {
    final idx = _convs.indexWhere((c) => c['id'] == convId);
    if (idx == -1) {
      // Шинэ conversation — дахин ачаална
      _load();
      return;
    }
    if (!mounted) return;
    setState(() {
      _convs[idx]['lastMsg']  = nm['content'] ?? '';
      _convs[idx]['lastTime'] = nm['created_at'] ?? _convs[idx]['lastTime'];
      final myUid = supabase.auth.currentUser?.id;
      if (nm['sender_id'] != myUid) {
        _convs[idx]['unread'] = (_convs[idx]['unread'] as int? ?? 0) + 1;
      }
      final conv = _convs.removeAt(idx);
      _convs.insert(0, conv);
    });
  }

  Future<void> _openOrCreateDirect(String otherUserId, String otherName) async {
    final uid = supabase.auth.currentUser?.id; if (uid == null) return;

    // Efficient: join query to find existing direct conv in one request
    String? existingConvId;
    try {
      final myIds = await supabase.from('conversation_members').select('conversation_id').eq('user_id', uid);
      final otherIds = await supabase.from('conversation_members').select('conversation_id').eq('user_id', otherUserId);
      final mySet = Set<String>.from((myIds as List).map((e) => e['conversation_id'] as String));
      final otherSet = Set<String>.from((otherIds as List).map((e) => e['conversation_id'] as String));
      final common = mySet.intersection(otherSet);
      for (final cid in common) {
        final conv = await supabase.from('conversations').select('type').eq('id', cid).eq('type', 'direct').maybeSingle();
        if (conv != null) { existingConvId = cid; break; }
      }
    } catch (_) {}

    if (existingConvId == null) {
      final nc = await supabase.from('conversations').insert({'type': 'direct'}).select().single();
      existingConvId = nc['id'] as String;
      await supabase.from('conversation_members').insert([
        {'conversation_id': existingConvId, 'user_id': uid},
        {'conversation_id': existingConvId, 'user_id': otherUserId},
      ]);
    }
    // Тухайн хэрэглэгчийн avatar_url-ыг авна (icon: эсвэл https://...)
    String? otherAvatarUrl;
    try {
      final ui = await supabase.from('users').select('avatar_url').eq('id', otherUserId).maybeSingle();
      final av = ui?['avatar_url'] as String?;
      if (av != null && av.isNotEmpty) otherAvatarUrl = av;
    } catch (_) {}

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<ThemeProvider>(),
      child: ChatDetailScreen(
        convId: existingConvId!,
        name: otherName,
        initials: otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
        isGroup: false,
        otherUserId: otherUserId,
        isOnline: _onlineIds.contains(otherUserId),
        avatarUrl: otherAvatarUrl,
      ),
    ))).then((_) { _searchCtrl.clear(); setState(() { _searchResults = []; _showSearch = false; }); _load(); });
  }

  // Avatar content — icon, URL, initials дэмжинэ
  Widget _buildAvatarContent(String? avatarUrl, String initials, Color fallbackColor) {
    final tc = context.read<ThemeProvider>().colors;
    return buildUserAvatar(
      avatarUrl: avatarUrl,
      initials: initials,
      fallbackColor: fallbackColor,
      size: 56,
      themeColors: tc,
    );
  }

  void _openAiChat() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<ThemeProvider>(), child: const AiChatScreen())));
  }

  String _fmtTime(String? t) {
    if (t == null) return ''; final dt = DateTime.tryParse(t)?.toLocal(); if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Column(children: [
      // ── Gradient search header ──────────────────────────
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.primary, c.accent.withOpacity(0.9)]),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: GestureDetector(
              onTap: () => setState(() { _showSearch = !_showSearch; if (!_showSearch) { _searchCtrl.clear(); _searchResults = []; } }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.25))),
                child: _showSearch
                    ? Row(children: [
                        const Icon(Icons.search_rounded, color: Colors.white70, size: 18), const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _searchCtrl, autofocus: true, style: const TextStyle(color: Colors.white, fontSize: 14), onChanged: _searchUsers,
                          decoration: InputDecoration(hintText: 'Хэрэглэгч хайх...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero))),
                        if (_searchingUsers) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        else GestureDetector(onTap: () => setState(() { _showSearch = false; _searchCtrl.clear(); _searchResults = []; }), child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18)),
                      ])
                    : Row(children: [
                        const Icon(Icons.search_rounded, color: Colors.white70, size: 18), const SizedBox(width: 10),
                        Text('Хэрэглэгч хайх...', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                      ]),
              ),
            ),
          ),

          // Online story circles — "Онлайн" текстгүй
          if (!_showSearch && _onlineMembers.isNotEmpty)
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
                itemCount: _onlineMembers.length,
                itemBuilder: (_, i) {
                  final m = _onlineMembers[i];
                  final color = Color(int.parse((m['color'] as String).replaceFirst('#', '0xFF')));
                  final isOnline = _onlineIds.contains(m['id'] as String);
                  final avatarUrl = m['avatar_url'] as String?;

                  return GestureDetector(
                    onTap: () => _openOrCreateDirect(m['id'] as String, m['name'] as String),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Stack(clipBehavior: Clip.none, children: [
                          // Story ring
                          Container(
                            width: 62, height: 62,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isOnline ? const LinearGradient(
                                colors: [Color(0xFF2DB87A), Color(0xFF4F8EF7)],
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                              ) : null,
                              border: isOnline ? null : Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                            ),
                            padding: const EdgeInsets.all(3),
                            // Container-ын color арилгасан — icon бол өөрийн tinted bg-тэй,
                            // URL бол зураг бүхэл зайг эзэлнэ, initials бол fallbackColor.
                            // Hardcoded color давхарлахаас сэргийлж icon-ы жинхэнэ өнгийг хадгална.
                            child: ClipOval(child: _buildAvatarContent(avatarUrl, m['initials'] as String, color)),
                          ),
                          // Ногоон цэг — баруун доод буланд
                          if (isOnline) Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 17, height: 17,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2DB87A),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [BoxShadow(color: const Color(0xFF2DB87A).withOpacity(0.5), blurRadius: 6)],
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 5),
                        SizedBox(
                          width: 60,
                          child: Text(m['name'] as String,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            )
          else const SizedBox(height: 4),
        ]),
      ),

      // Search results dropdown
      if (_showSearch && _searchResults.isNotEmpty)
        Container(
          constraints: const BoxConstraints(maxHeight: 220), margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: c.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border.withOpacity(0.15)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 14, offset: const Offset(0, 4))]),
          child: ListView.builder(shrinkWrap: true, padding: const EdgeInsets.symmetric(vertical: 6), itemCount: _searchResults.length, itemBuilder: (_, i) {
            final user = _searchResults[i]; final name = user['full_name'] as String? ?? 'Хэрэглэгч'; final code = user['student_code'] as String? ?? '';
            final cls = [const Color(0xFFE8547A), const Color(0xFF4F8EF7), const Color(0xFF2DB87A), const Color(0xFF7C5CBF)];
            final avUrl = user['avatar_url'] as String?;
            final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
            return GestureDetector(onTap: () => _openOrCreateDirect(user['id'] as String, name),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: ClipOval(
                      child: buildUserAvatar(
                        avatarUrl: avUrl,
                        initials: initials,
                        fallbackColor: cls[i % cls.length],
                        size: 44,
                        themeColors: c,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: TextStyle(color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    if (code.isNotEmpty) Text(code, style: TextStyle(color: c.textMuted, fontSize: 12)),
                  ])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(gradient: LinearGradient(colors: [c.primary, c.accent]), borderRadius: BorderRadius.circular(12)),
                    child: const Text('Мессеж', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
                ])));
          }),
        ),

      // Conversation list
      Expanded(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: c.primary, strokeWidth: 2))
            : RefreshIndicator(
                onRefresh: _load, color: c.primary,
                child: ListView(
                  padding: const EdgeInsets.only(top: 10, bottom: 20),
                  children: [
                    // ── AI Card — эхэнд ──────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      child: _AiConvCard(onTap: _openAiChat, c: c),
                    ),
                    const SizedBox(height: 7),

                    // ── Regular conversations ────────────────────────
                    if (_convs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Center(child: Column(children: [
                          Container(width: 64, height: 64, decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle), child: Icon(Icons.chat_bubble_outline_rounded, color: c.textMuted, size: 30)),
                          const SizedBox(height: 12),
                          Text('Мессеж байхгүй байна', style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text('Дээрх хайлтаар хэрэглэгч хайгаарай', style: TextStyle(color: c.textMuted, fontSize: 12)),
                        ])),
                      )
                    else
                      ..._convs.map((conv) => Padding(
                        padding: const EdgeInsets.fromLTRB(13, 0, 13, 7),
                        child: _ConvTile(
                          conv: conv, c: c,
                          timeStr: _fmtTime(conv['lastTime'] as String?),
                          isOnline: !(conv['isGroup'] as bool) && _onlineIds.contains(conv['otherUserId']),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<ThemeProvider>(),
                            child: ChatDetailScreen(
                              convId: conv['id'] as String,
                              name: conv['name'] as String,
                              initials: conv['initials'] as String,
                              isGroup: conv['isGroup'] as bool,
                              isOnline: !(conv['isGroup'] as bool) && _onlineIds.contains(conv['otherUserId']),
                              otherUserId: conv['otherUserId'] as String?,
                              avatarUrl: conv['avatar_url'] as String?,
                            )))).then((_) => _load()),
                        ),
                      )),
                  ],
                ),
              ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// AI CONV CARD — Special card at top of list
// ─────────────────────────────────────────────────────────────
class _AiConvCard extends StatelessWidget {
  final VoidCallback onTap;
  final ThemeColors c;
  const _AiConvCard({required this.onTap, required this.c});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [c.primary.withOpacity(0.2), c.accent.withOpacity(0.1)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.primary.withOpacity(0.32)),
          boxShadow: [BoxShadow(color: c.primary.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          // AI avatar
          Container(
            width: 54, height: 54, decoration: BoxDecoration(gradient: c.accentGradient, shape: BoxShape.circle, boxShadow: [BoxShadow(color: c.primary.withOpacity(0.4), blurRadius: 12)]),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShaderMask(
              shaderCallback: (b) => LinearGradient(colors: [c.primary, c.accent]).createShader(b),
              child: const Text('ClubHub AI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(height: 3),
            Text('Тохирсон клубоо олоход тусалъя', style: TextStyle(fontSize: 12, color: c.textMuted)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(gradient: c.accentGradient, borderRadius: BorderRadius.circular(8)),
            child: const Text('AI', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CONV TILE — card style
// ─────────────────────────────────────────────────────────────
class _ConvTile extends StatelessWidget {
  final Map<String, dynamic> conv;
  final ThemeColors c;
  final bool isOnline;
  final String timeStr;
  final VoidCallback onTap;
  const _ConvTile({required this.conv, required this.c, required this.isOnline, required this.timeStr, required this.onTap});

  String _lastSeenText() {
    // isOnline = presence-ээр тогтоогдоно (бодит)
    if (isOnline) return 'Онлайн байна';
    final lastMsg = conv['lastTime'] as String?;
    if (lastMsg == null) return 'Мессеж байхгүй';
    final dt = DateTime.tryParse(lastMsg)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 5) return 'Дөнгөж саяхан';
    if (diff.inMinutes < 60) return '${diff.inMinutes} минутын өмнө';
    if (diff.inHours < 24) return '${diff.inHours} цагийн өмнө';
    if (diff.inDays == 1) return 'Өчигдөр орсон';
    if (diff.inDays < 7) return '${diff.inDays} өдрийн өмнө';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse((conv['color'] as String).replaceFirst('#', '0xFF')));
    final unread = (conv['unread'] as int?) ?? 0;
    final lastMsg = conv['lastMsg'] as String? ?? '';
    final isGroup = conv['isGroup'] as bool;
    final avatarUrl = conv['avatar_url'] as String?;
    final hasIcon  = !isGroup && _avatarIconIndex(avatarUrl) != null;
    final hasPhoto = !isGroup && avatarUrl != null && avatarUrl.isNotEmpty && !hasIcon;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.bgCard, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border.withOpacity(0.08)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Stack(children: [
            // Avatar — icon, зураг эсвэл initials
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: (hasPhoto || hasIcon) ? null : color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: ClipOval(
                child: isGroup
                    ? const Center(child: Icon(Icons.group_rounded, color: Colors.white, size: 24))
                    : buildUserAvatar(
                        avatarUrl: avatarUrl,
                        initials: conv['initials'] as String,
                        fallbackColor: color,
                        size: 54,
                        themeColors: c,
                      ),
              ),
            ),
            if (!isGroup && isOnline) Positioned(bottom: 1, right: 1,
              child: Container(width: 15, height: 15,
                decoration: BoxDecoration(color: const Color(0xFF2DB87A), shape: BoxShape.circle,
                  border: Border.all(color: c.bgCard, width: 2.5)))),
            if (isGroup) Positioned(bottom: 0, right: 0,
              child: Container(width: 20, height: 20,
                decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle,
                  border: Border.all(color: c.bgCard, width: 2)),
                child: const Icon(Icons.group_rounded, color: Colors.white, size: 11))),
          ]),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(conv['name'] as String,
                style: TextStyle(color: c.textPrimary, fontSize: 15,
                  fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(timeStr, style: TextStyle(color: unread > 0 ? c.primary : c.textMuted,
                fontSize: 11, fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.normal)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: Text(
                isGroup ? (lastMsg.isEmpty ? 'Мессеж байхгүй' : lastMsg) : _lastSeenText(),
                style: TextStyle(
                  color: isOnline ? const Color(0xFF2DB87A) : (unread > 0 ? c.textSecondary : c.textMuted),
                  fontSize: 13, fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (unread > 0)
                Container(margin: const EdgeInsets.only(left: 8), width: 22, height: 22,
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [c.primary, c.accent]),
                    shape: BoxShape.circle),
                  child: Center(child: Text('$unread',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)))),
            ]),
          ])),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// AI CHAT SCREEN — full screen, no tabs
// ═══════════════════════════════════════════════════════════
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});
  @override State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;
  static const _edgeFnUrl = 'https://vmglqlkuuijfilpfnves.supabase.co/functions/v1/gemini-chat';
  String _systemPrompt = 'Та ХУИС-ийн ClubHub апп-ийн AI туслах юм. Монгол хэлээр найрсаг хариулна.';

  static const _quickQuestions = [
    (Icons.track_changes_rounded,  Color(0xFFE8547A), 'Надад тохирсон клуб олоод өгнө үү'),
    (Icons.assignment_rounded,     Color(0xFF4F8EF7), 'Клубт элсэх заавар'),
    (Icons.volunteer_activism_rounded, Color(0xFFF5A623), 'Сайн дурын цаг гэж юу вэ?'),
    (Icons.phone_android_rounded,  Color(0xFF7C5CBF), 'ClubHub хэрхэн ашиглах вэ?'),
    (Icons.emoji_events_rounded,   Color(0xFF2DB87A), 'Клубт байгаа ашиг тус юу вэ?'),
  ];

  @override void initState() { super.initState(); _loadContext(); }

  Future<void> _loadContext() async {
    try {
      final uid = supabase.auth.currentUser?.id;
      final clubs = await supabase.from('clubs').select('name, category').limit(50);
      List<String> myClubs = [];
      if (uid != null) {
        final myM = await supabase.from('club_memberships').select('clubs(name)').eq('user_id', uid).eq('status', 'approved');
        myClubs = (myM as List).map((m) => (m['clubs'] as Map?)?['name'] as String? ?? '').where((n) => n.isNotEmpty).toList();
      }
      final events = await supabase.from('events').select('title, clubs(name)').gte('event_date', DateTime.now().toIso8601String()).order('event_date', ascending: true).limit(10);
      final clubList = (clubs as List).map((c) => '${c['name']} (${c['category']})').join('; ');
      final eventList = (events as List).map((e) => '${e['title']} (${(e['clubs'] as Map?)?['name'] ?? ''})').join('; ');
      if (mounted) setState(() { _systemPrompt = 'ХУИС-ийн ClubHub AI туслах. Монгол хэлээр найрсаг хариулна. Клубууд: ${myClubs.isNotEmpty ? myClubs.join(', ') : 'Элсээгүй'}. Бүх клубууд: $clubList. Ирэх арга хэмжээ: $eventList.'; });
    } catch (_) {}
  }

  Future<void> _send([String? quick]) async {
    final text = quick ?? _msgCtrl.text.trim();
    if (text.isEmpty || _loading) return;
    _msgCtrl.clear();
    setState(() { _messages.add({'role': 'user', 'content': text}); _loading = true; });
    _scrollToBottom();
    try {
      final contents = [
        {'role': 'user', 'parts': [{'text': _systemPrompt}]},
        {'role': 'model', 'parts': [{'text': 'Ойлголоо!'}]},
        ..._messages.map((m) => {'role': m['role'] == 'user' ? 'user' : 'model', 'parts': [{'text': m['content']!}]}),
      ];
      final res = await http.post(Uri.parse(_edgeFnUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'contents': contents}));
      final reply = res.statusCode == 200 ? jsonDecode(res.body)['reply'] as String? ?? 'Хариулт олдсонгүй' : 'Алдаа гарлаа.';
      if (mounted) setState(() { _messages.add({'role': 'assistant', 'content': reply}); _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _messages.add({'role': 'assistant', 'content': 'Холболтын алдаа гарлаа.'}); _loading = false; });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  });

  @override void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Scaffold(
      backgroundColor: c.bgDark,
      appBar: AppBar(
        backgroundColor: c.bgCard,
        elevation: 0, surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_rounded, color: c.textPrimary, size: 18), onPressed: () => Navigator.pop(context)),
        titleSpacing: 0,
        title: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(gradient: c.accentGradient, shape: BoxShape.circle, boxShadow: [BoxShadow(color: c.primary.withOpacity(0.35), blurRadius: 10)]),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShaderMask(shaderCallback: (b) => LinearGradient(colors: [c.primary, c.accent]).createShader(b),
              child: const Text('ClubHub AI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
            Row(children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF2DB87A), shape: BoxShape.circle)),
              const SizedBox(width: 5),
              const Text('Онлайн', style: TextStyle(color: Color(0xFF2DB87A), fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: ListView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(14, 20, 14, 10),
            children: [
              // ── Hero (зөвхөн хоосон үед) ──────────────────
              if (_messages.isEmpty) ...[
                Center(child: Column(children: [
                  Container(width: 70, height: 70, decoration: BoxDecoration(gradient: c.accentGradient, shape: BoxShape.circle, boxShadow: [BoxShadow(color: c.primary.withOpacity(0.4), blurRadius: 24)]),
                    child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 34)),
                  const SizedBox(height: 12),
                  Text('ClubHub AI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Тохирсон клубоо олоход тусалъя!', style: TextStyle(fontSize: 13, color: c.textMuted)),
                ])),
                const SizedBox(height: 20),
              ],

              // ── Chat bubbles ─────────────────────────────
              ..._messages.map((m) => _buildBubble(m['content']!, m['role'] == 'user', c)),

              // ── Typing indicator ─────────────────────────
              if (_loading) _buildTyping(c),

              // ── Quick questions — ЗӨВХӨН чат хоосон үед inline харуулна.
              //   Чат эхлэхэд эдгээр нь алга болж input bar-ын icon руу шилжинэ.
              if (_messages.isEmpty) ...[
                const SizedBox(height: 16),
                _buildQuickQuestions(c),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),

        // ── Input bar ─────────────────────────────────────
        Container(
          padding: EdgeInsets.only(left: 14, right: 14, top: 10, bottom: MediaQuery.of(context).viewInsets.bottom + 14),
          decoration: BoxDecoration(color: c.bgCard, border: Border(top: BorderSide(color: c.border.withOpacity(0.12)))),
          child: Row(children: [
            // Чатлаж эхэлмэгц quick-questions icon гарна
            if (_messages.isNotEmpty) ...[
              GestureDetector(
                onTap: () => _showQuickQuestionsSheet(),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: c.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: c.primary.withOpacity(0.3)),
                  ),
                  child: Icon(Icons.lightbulb_outline_rounded, color: c.primary, size: 22),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(child: Container(
              constraints: const BoxConstraints(minHeight: 42, maxHeight: 110),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: c.border.withOpacity(0.2))),
              child: TextField(controller: _msgCtrl, style: TextStyle(fontSize: 14, color: c.textPrimary), maxLines: null, textInputAction: TextInputAction.send, onSubmitted: (_) => _send(),
                decoration: InputDecoration(hintText: 'Асуулт бичнэ үү...', hintStyle: TextStyle(color: c.textMuted, fontSize: 14), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11))),
            )),
            const SizedBox(width: 10),
            GestureDetector(onTap: () => _send(),
              child: Container(width: 44, height: 44, decoration: BoxDecoration(gradient: c.accentGradient, shape: BoxShape.circle, boxShadow: [BoxShadow(color: c.primary.withOpacity(0.4), blurRadius: 12)]),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20))),
          ]),
        ),
      ]),
    );
  }

  /// Чатлаж эхэлсний дараа нээгдэх Quick-questions modal bottom sheet
  void _showQuickQuestionsSheet() {
    final tp = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetCtx) => ChangeNotifierProvider.value(
        value: tp,
        child: Builder(builder: (innerCtx) {
          final c = innerCtx.watch<ThemeProvider>().colors;
          return Container(
            decoration: BoxDecoration(
              color: c.bgCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: c.border.withOpacity(0.12)),
            ),
            padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(innerCtx).padding.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(child: Container(
                  width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
                )),
                Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(gradient: c.accentGradient, shape: BoxShape.circle),
                    child: const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Түгээмэл асуултууд',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Сонгож шууд асууж болно',
                      style: TextStyle(fontSize: 12, color: c.textMuted)),
                  ])),
                  GestureDetector(
                    onTap: () => Navigator.pop(innerCtx),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle),
                      child: Icon(Icons.close_rounded, color: c.textMuted, size: 18),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                ..._quickQuestions.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(innerCtx);
                      _send(item.$3);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.border.withOpacity(0.15)),
                      ),
                      child: Row(children: [
                        Container(width: 36, height: 36,
                          decoration: BoxDecoration(color: item.$2.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
                          child: Icon(item.$1, color: item.$2, size: 18)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(item.$3,
                          style: TextStyle(fontSize: 13, color: c.textPrimary, fontWeight: FontWeight.w600))),
                        Icon(Icons.send_rounded, size: 16, color: c.textMuted),
                      ]),
                    ),
                  ),
                )),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBubble(String text, bool isMe, ThemeColors c) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.end, children: [
      if (!isMe) ...[
        Container(width: 30, height: 30, decoration: BoxDecoration(gradient: c.accentGradient, shape: BoxShape.circle), child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16)),
        const SizedBox(width: 7),
      ],
      Flexible(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe ? c.accentGradient : null, color: isMe ? null : c.bgCard,
          borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(isMe ? 18 : 4), bottomRight: Radius.circular(isMe ? 4 : 18)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Text(text, style: TextStyle(fontSize: 14, height: 1.5, color: isMe ? Colors.white : c.textPrimary)),
      )),
    ]),
  );

  Widget _buildTyping(ThemeColors c) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Container(width: 30, height: 30, decoration: BoxDecoration(gradient: c.accentGradient, shape: BoxShape.circle), child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16)),
      const SizedBox(width: 7),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(color: c.bgCard, borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18))),
        child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) => _DotPulse(delay: i * 180, color: c.primary))),
      ),
    ]),
  );

  Widget _buildQuickQuestions(ThemeColors c) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 8),
        child: Text('Түгээмэл асуултууд', style: TextStyle(fontSize: 11, color: c.textMuted, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ),
      ..._quickQuestions.map((item) => GestureDetector(
        onTap: () => _send(item.$3),
        child: Container(
          width: double.infinity, margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: c.bgCard, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border.withOpacity(0.1)),
          ),
          child: Row(children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: item.$2.withOpacity(0.14), borderRadius: BorderRadius.circular(9)), child: Icon(item.$1, color: item.$2, size: 16)),
            const SizedBox(width: 10),
            Expanded(child: Text(item.$3, style: TextStyle(fontSize: 13, color: c.textPrimary, fontWeight: FontWeight.w500))),
            Icon(Icons.arrow_forward_ios_rounded, size: 11, color: c.textMuted),
          ]),
        ),
      )),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════
// CHAT DETAIL SCREEN
// ═══════════════════════════════════════════════════════════
class ChatDetailScreen extends StatefulWidget {
  final String convId, name, initials;
  final bool isGroup;
  final bool isOnline;
  final String? otherUserId;
  final String? avatarUrl;
  const ChatDetailScreen({super.key, required this.convId, required this.name, required this.initials, required this.isGroup, this.isOnline = false, this.otherUserId, this.avatarUrl});
  @override State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  final Set<String> _processingIds = {}; // _ingestMessage race-аас сэргийлэх
  Map<String, String> _userNames = {};
  Map<String, String?> _userAvatars = {}; // sender_id → avatar_url
  bool _loading = true, _sending = false, _showMediaMenu = false, _isRecording = false;
  bool _showScrollToBottom = false; // Дээр гүйлгэсэн үед floating товч харуулна
  int _newMessageCount = 0;          // Гүйлгээтэй үед ирсэн уншаагүй мессежийн тоо
  RealtimeChannel? _channel;
  String? _myUid;
  late AnimationController _mediaAnimCtrl;
  late Animation<double> _mediaAnim;
  final _recorder = AudioRecorder();

  @override
  void initState() {
    super.initState();
    _myUid = supabase.auth.currentUser?.id;
    _mediaAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _mediaAnim = CurvedAnimation(parent: _mediaAnimCtrl, curve: Curves.easeOutBack);
    _scrollCtrl.addListener(_onScroll);
    _loadMessages(); _markSeen(); _subscribeRealtime();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final dist = _scrollCtrl.position.maxScrollExtent - _scrollCtrl.position.pixels;
    final shouldShow = dist > 200; // 200px-аас илүү дээр гүйлгэсэн бол товчийг харуулна
    if (shouldShow != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = shouldShow;
        if (!shouldShow) _newMessageCount = 0; // дооно очвол counter цэвэрлэнэ
      });
    }
  }

  Timer? _pollTimer;
  String? _lastMessageTime; // ISO timestamp of newest known message — polling cursor

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _ctrl.dispose(); _scrollCtrl.dispose();
    _channel?.unsubscribe();
    _recordTimer?.cancel();
    _pollTimer?.cancel();
    _mediaAnimCtrl.dispose(); _recorder.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final msgs = await supabase.from('messages')
        .select('*, sender:sender_id(full_name, avatar_url)')
        .eq('conversation_id', widget.convId)
        .order('created_at', ascending: true).limit(100);
    final names = <String, String>{};
    final avatars = <String, String?>{};
    String? newest;
    for (final m in (msgs as List)) {
      final sid = m['sender_id'] as String;
      if (m['sender'] != null) {
        names[sid] = m['sender']['full_name'] as String? ?? 'Хэрэглэгч';
        final av = m['sender']['avatar_url'] as String?;
        avatars[sid] = (av != null && av.isNotEmpty) ? av : null;
      }
      final t = m['created_at'] as String?;
      if (t != null && (newest == null || t.compareTo(newest) > 0)) newest = t;
    }
    if (mounted) setState(() {
      _messages = List<Map<String, dynamic>>.from(msgs);
      _userNames = names;
      _userAvatars = avatars;
      _loading = false;
      _lastMessageTime = newest;
    });
    // Эхний load үед шууд үсэрнэ (animation үед хуучин мессеж сэжих явдал болохгүй)
    _scrollToBottom(animate: false);
  }

  void _subscribeRealtime() {
    // 1) Postgres-changes realtime (хамгийн хурдан)
    _channel = supabase.channel('chat_${widget.convId}')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public', table: 'messages',
        callback: (payload) async {
          final nm = payload.newRecord;
          if (nm['conversation_id'] != widget.convId) return;
          await _ingestMessage(nm);
        })
      .subscribe((status, err) {
        debugPrint('[chat] realtime status=$status err=$err');
      });

    // 2) Polling fallback — Supabase realtime publication-д хүснэгт нэмээгүй
    //    эсвэл сүлжээ үймэгдсэн ч мессеж алдагдахгүй болгох. 2.5с тутамд шалгана.
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) async {
      if (!mounted) return;
      await _pollNewMessages();
    });
  }

  /// Нэг мессежийг list-д нэмэх: temp орлуулах, давхардуулахгүй, sender-ийг fetch.
  Future<void> _ingestMessage(Map<String, dynamic> nm) async {
    final newId = nm['id']?.toString();

    // ⚠️ ДУПЛИКАТ-аас сэргийлэх — async await хийхээс ӨМНӨ шалгана.
    // Realtime + polling parallel ажиллахад ижил мессеж 2 удаа орохоос сэргийлнэ.
    if (newId != null) {
      if (_messages.any((m) => m['id']?.toString() == newId)) return;
      if (_processingIds.contains(newId)) return;
      _processingIds.add(newId);
    }

    try {
      final sid = nm['sender_id'] as String?;
      if (sid != null && !_userNames.containsKey(sid)) {
        try {
          final u = await supabase.from('users').select('full_name, avatar_url').eq('id', sid).single();
          _userNames[sid] = u['full_name'] as String? ?? 'Хэрэглэгч';
          final av = u['avatar_url'] as String?;
          _userAvatars[sid] = (av != null && av.isNotEmpty) ? av : null;
        } catch (_) {}
      }
      if (!mounted) return;
      final newTime = nm['created_at'] as String?;
      setState(() {
        // Дахин шалгана — await хийсний дараа list өөрчлөгдсөн байж болно
        if (newId != null && _messages.any((m) => m['id']?.toString() == newId)) return;
        // Өөрийн илгээсэн temp мессеж бол solibni
        if (sid == _myUid) {
          final tempIdx = _messages.indexWhere((m) =>
              m['_pending'] == true &&
              m['content'] == nm['content'] &&
              (m['media_type'] ?? '') == (nm['media_type'] ?? ''));
          if (tempIdx != -1) {
            _messages[tempIdx] = nm;
            if (newTime != null && (_lastMessageTime == null || newTime.compareTo(_lastMessageTime!) > 0)) {
              _lastMessageTime = newTime;
            }
            return;
          }
        }
        _messages.add(nm);
        if (newTime != null && (_lastMessageTime == null || newTime.compareTo(_lastMessageTime!) > 0)) {
          _lastMessageTime = newTime;
        }
      });
      // Хэрэглэгч доод хэсэгт байсан эсвэл өөрөө мессеж явуулсан бол доош scroll
      // хийнэ. Үгүй (хуучин мессеж уншиж байгаа) бол байрлалыг нь хадгална —
      // оронд нь "Scroll to bottom" товчинд unread counter нэмэгдэнэ.
      final mySend = nm['sender_id'] == _myUid;
      if (mySend || _isNearBottom()) {
        _scrollToBottom();
      } else if (mounted) {
        setState(() {
          _showScrollToBottom = true;
          _newMessageCount += 1;
        });
      }
      _markSeen();
    } finally {
      if (newId != null) _processingIds.remove(newId);
    }
  }

  /// Realtime fallback — _lastMessageTime-аас хойших шинэ мессежийг авна.
  Future<void> _pollNewMessages() async {
    try {
      var q = supabase
          .from('messages')
          .select('*, sender:sender_id(full_name, avatar_url)')
          .eq('conversation_id', widget.convId);
      if (_lastMessageTime != null) {
        q = q.gt('created_at', _lastMessageTime!);
      }
      final rows = await q.order('created_at', ascending: true).limit(50);
      for (final m in (rows as List)) {
        final mp = Map<String, dynamic>.from(m as Map);
        // Sender info-г cache-д хадгална
        if (mp['sender'] is Map) {
          final sid = mp['sender_id'] as String?;
          if (sid != null) {
            _userNames[sid] = (mp['sender']['full_name'] as String?) ?? 'Хэрэглэгч';
            final av = mp['sender']['avatar_url'] as String?;
            _userAvatars[sid] = (av != null && av.isNotEmpty) ? av : null;
          }
        }
        await _ingestMessage(mp);
      }
    } catch (e) {
      debugPrint('[chat] poll алдаа: $e');
    }
  }

  // ── Ирж буй дуудлагын урилга сонсоно ─────────────────────
  // DB-based incoming call listener ChatTabScreen-д байна — энд хэрэггүй

  Future<void> _markSeen() async {
    if (_myUid == null) return;
    await supabase.from('conversation_members').update({'last_seen_at': DateTime.now().toIso8601String()}).eq('conversation_id', widget.convId).eq('user_id', _myUid!);
  }

  Future<void> _send([String? ov]) async {
    final text = ov ?? _ctrl.text.trim();
    if (text.isEmpty || _myUid == null) return;
    _ctrl.clear();

    // Optimistic — шууд харуулна, DB-г background-д явуулна
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = {
      'id': tempId,
      'conversation_id': widget.convId,
      'sender_id': _myUid!,
      'content': text,
      'created_at': DateTime.now().toIso8601String(),
      'sender': {'full_name': 'Би'},
      '_pending': true,
    };
    if (mounted) setState(() => _messages.add(tempMsg));
    _scrollToBottom();

    // DB insert — `select().single()` ашиглаж бодит row-г шууд буцааж авна.
    // Энэ нь tempMsg-ийг real ID-тай мессежээр солих боломж олгож, дараа нь
    // realtime/poll давхардуулахаас сэргийлнэ (id-аар dedupe ажиллана).
    supabase.from('messages').insert({
      'conversation_id': widget.convId,
      'sender_id': _myUid!,
      'content': text,
    }).select().single().then((row) {
      if (!mounted) return;
      final realId = row['id']?.toString();
      setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == tempId);
        if (idx != -1) {
          // Хэрэв энэ хооронд realtime/poll нь нэгэнт орлуулсан бол `idx == -1`
          // байж магадгүй. Олдсон бол real row-р солино.
          _messages[idx] = Map<String, dynamic>.from(row);
        }
        // Хэрэв realtime аль хэдийн real row-г жагсаалтад нэмж амжсан бол
        // tempMsg тэдний дунд үлдээгүй учир давхардахгүй.
      });
      // realId орсон тул дараа нь ингест хийх realtime/poll давхардуулахгүй
      if (realId != null) _processingIds.remove(realId);
    }).catchError((e) {
      if (mounted) setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == tempId);
        if (idx != -1) _messages[idx] = {..._messages[idx], '_error': true, '_pending': false};
      });
    });
  }

  void _toggleMediaMenu() {
    setState(() => _showMediaMenu = !_showMediaMenu);
    if (_showMediaMenu) _mediaAnimCtrl.forward(from: 0); else _mediaAnimCtrl.reverse();
  }

  Future<void> _pickImage() async {
    _toggleMediaMenu();
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (picked == null || _myUid == null) return;
    try {
      final bytes = await picked.readAsBytes();
      final path = 'chat/${widget.convId}/${DateTime.now().millisecondsSinceEpoch}.${picked.name.split('.').last}';
      await supabase.storage.from('chat_media').uploadBinary(path, bytes, fileOptions: FileOptions(contentType: picked.mimeType ?? 'image/jpeg', upsert: true));
      final url = supabase.storage.from('chat_media').getPublicUrl(path);
      await supabase.from('messages').insert({'conversation_id': widget.convId, 'sender_id': _myUid!, 'content': '📷 Зураг', 'media_url': url, 'media_type': 'image'});
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Алдаа: $e'))); }
  }

  Future<void> _pickFile() async {
    _toggleMediaMenu();
    if (_myUid == null) return;

    // withData: true → web ч, mobile ч bytes-аа шууд авна.
    // file.path mobile дээр л байна, web дээр null учир bytes ашиглана.
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(withData: true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл сонгох үед алдаа: $e')));
      return;
    }
    if (result == null || result.files.isEmpty) return; // хэрэглэгч цуцалсан
    final picked = result.files.first;

    // Bytes-ээ авна — web дээр picked.bytes, mobile дээр path-аас уншина
    Uint8List? bytes = picked.bytes;
    if (bytes == null && picked.path != null) {
      try { bytes = await File(picked.path!).readAsBytes(); } catch (_) {}
    }
    if (bytes == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файлыг уншиж чадсангүй')));
      return;
    }
    // 50MB-ээс хэтэрвэл анхааруулна (Supabase free plan-ийн хязгаар)
    if (bytes.length > 50 * 1024 * 1024) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файлын хэмжээ 50MB-ээс хэтэрсэн')));
      return;
    }

    // ── Optimistic UI: дарвал шууд "uploading" bubble харуулна ───────────
    final tempId = 'tempfile_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = <String, dynamic>{
      'id': tempId,
      'conversation_id': widget.convId,
      'sender_id': _myUid!,
      'content': '📎 ${picked.name}',
      'media_type': 'file',
      'created_at': DateTime.now().toIso8601String(),
      '_pending': true,
    };
    if (mounted) setState(() => _messages.add(tempMsg));
    _scrollToBottom();

    // ── Upload + DB insert (background) ───────────────────────────────
    try {
      final safeName = picked.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final path = 'chat/${widget.convId}/${DateTime.now().millisecondsSinceEpoch}_$safeName';
      await supabase.storage.from('chat_media').uploadBinary(
        path, bytes,
        fileOptions: FileOptions(upsert: true, contentType: _guessMime(picked.name)),
      );
      final url = supabase.storage.from('chat_media').getPublicUrl(path);
      final row = await supabase.from('messages').insert({
        'conversation_id': widget.convId,
        'sender_id': _myUid!,
        'content': '📎 ${picked.name}',
        'media_url': url,
        'media_type': 'file',
      }).select().single();
      // Temp-ийг real row-р солино
      if (mounted) setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == tempId);
        if (idx != -1) _messages[idx] = Map<String, dynamic>.from(row);
      });
    } catch (e) {
      debugPrint('File upload алдаа: $e');
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m['id'] == tempId);
          if (idx != -1) _messages[idx] = {..._messages[idx], '_error': true, '_pending': false};
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Файл upload алдаа: $e')));
      }
    }
  }

  /// File-ийн extension-аас MIME type-г таамаглах
  String? _guessMime(String filename) {
    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
    const map = {
      'png':  'image/png',  'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
      'gif':  'image/gif',  'webp': 'image/webp', 'bmp': 'image/bmp',
      'pdf':  'application/pdf',
      'doc':  'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls':  'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt':  'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt':  'text/plain',
      'csv':  'text/csv',
      'json': 'application/json',
      'zip':  'application/zip',
      'rar':  'application/vnd.rar',
      'mp3':  'audio/mpeg', 'wav': 'audio/wav', 'm4a': 'audio/mp4', 'ogg': 'audio/ogg',
      'mp4':  'video/mp4',  'mov': 'video/quicktime', 'webm': 'video/webm',
    };
    return map[ext];
  }

  DateTime? _recordStartedAt;
  Timer? _recordTimer;
  Duration _recordElapsed = Duration.zero;

  Future<void> _startRecording() async {
    if (_isRecording) return;
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Микрофон зөвшөөрөл шаардлагатай')));
      return;
    }
    final dir = await getTemporaryDirectory();
    await _recorder.start(const RecordConfig(),
        path: '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a');
    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _recordStartedAt = DateTime.now();
      _recordElapsed = Duration.zero;
    });
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted || _recordStartedAt == null) return;
      setState(() => _recordElapsed = DateTime.now().difference(_recordStartedAt!));
    });
  }

  Future<void> _stopAndSendRecording() async {
    if (!_isRecording) return;
    final path = await _recorder.stop();
    _recordTimer?.cancel(); _recordTimer = null;
    if (!mounted) return;
    setState(() { _isRecording = false; _recordStartedAt = null; });

    if (path == null || _myUid == null) return;
    // Хэт богино бол илгээхгүй
    if (_recordElapsed.inMilliseconds < 500) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Бичлэг хэт богино')));
      return;
    }

    // ── Optimistic UI: шууд чатанд харуулна, upload background-д явна
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = {
      'id':              tempId,
      'conversation_id': widget.convId,
      'sender_id':       _myUid!,
      'content':         '🎤 Дуут мессеж',
      'media_url':       path, // local file — upload болохоос өмнө тоглуулж болно
      'media_type':      'audio',
      'created_at':      DateTime.now().toIso8601String(),
      '_pending':        true,
    };
    setState(() => _messages.add(tempMsg));
    _scrollToBottom();

    // Background-д upload + insert
    () async {
      try {
        final bytes = await File(path).readAsBytes();
        final sp = 'chat/${widget.convId}/${DateTime.now().millisecondsSinceEpoch}.m4a';
        await supabase.storage.from('chat_media').uploadBinary(
          sp, bytes,
          fileOptions: const FileOptions(contentType: 'audio/m4a', upsert: true));
        final url = supabase.storage.from('chat_media').getPublicUrl(sp);
        final inserted = await supabase.from('messages').insert({
          'conversation_id': widget.convId,
          'sender_id':       _myUid!,
          'content':         '🎤 Дуут мессеж',
          'media_url':       url,
          'media_type':      'audio',
        }).select().single();
        // Temp-ийг бодит DB record-аар солино
        if (mounted) setState(() {
          final idx = _messages.indexWhere((m) => m['id'] == tempId);
          if (idx != -1) {
            _messages[idx] = inserted;
          } else if (!_messages.any((m) => m['id'] == inserted['id'])) {
            _messages.add(inserted);
          }
        });
      } catch (e) {
        if (mounted) {
          setState(() {
            final idx = _messages.indexWhere((m) => m['id'] == tempId);
            if (idx != -1) _messages[idx] = {..._messages[idx], '_error': true, '_pending': false};
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Алдаа: $e')));
        }
      }
    }();
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    try { await _recorder.stop(); } catch (_) {}
    _recordTimer?.cancel(); _recordTimer = null;
    if (!mounted) return;
    setState(() { _isRecording = false; _recordStartedAt = null; });
  }

  Future<void> _toggleRecording() async {
    _toggleMediaMenu();
    if (_isRecording) {
      await _stopAndSendRecording();
    } else {
      await _startRecording();
    }
  }

  void _showCallDialog(bool isVideo) {
    if (_myUid == null) return;
    final remoteUid = widget.otherUserId ?? '';
    if (remoteUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Группын чатад дуудлага хийх боломжгүй')));
      return;
    }
    supabase.from('users').select('full_name').eq('id', _myUid!).single().then((me) async {
      final fromName = me['full_name'] as String? ?? 'Хэрэглэгч';
      // call_logs-д insert → нөгөө талд postgres_changes-ээр хүрнэ
      final callId = await CallService.sendCallInvite(
        fromUid: _myUid!, toUid: remoteUid,
        fromName: fromName, convId: widget.convId, isVideo: isVideo,
      );
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<ThemeProvider>(),
          child: WebRtcCallScreen(
            callId:           callId ?? '',
            convId:           widget.convId,
            myUid:            _myUid!,
            remoteUid:        remoteUid,
            remoteName:       widget.name,
            remoteInitials:   widget.initials,
            remoteAvatarUrl:  widget.avatarUrl,  // Дуудаж байгаа хүний avatar
            isVideo:          isVideo,
            isCaller:         true,
            remoteOnline:     widget.isOnline,
          ),
        ),
      )).then((_) => _loadMessages());
    });
  }

  /// [animate=false] бол шууд үсэрнэ (initial load), [animate=true] бол гулсана (шинэ мессеж).
  /// Initial load үед image зэрэг late-loading content нь maxScrollExtent-г өөрчилдөг
  /// тул хэд хэдэн frame-ийн дараа давтан jumpTo хийж бүрэн доод хэсэгт хүрнэ.
  void _scrollToBottom({bool animate = true}) {
    void jump() {
      if (!mounted || !_scrollCtrl.hasClients) return;
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    }
    void smoothScroll() {
      if (!mounted || !_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }

    if (animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => smoothScroll());
    } else {
      // Initial load: дараалсан 4 удаа jumpTo — image/audio bubble-уудын
      // layout өөрчлөгдсөн ч заавал жинхэнэ доод хэсэгт хүрнэ.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        jump();
        Future.delayed(const Duration(milliseconds: 50), jump);
        Future.delayed(const Duration(milliseconds: 200), jump);
        Future.delayed(const Duration(milliseconds: 500), jump);
        Future.delayed(const Duration(milliseconds: 1000), jump);
      });
    }
  }

  /// Хэрэглэгч list-ийн доод хэсэгт байгаа эсэх (~120px дотор) — auto-scroll-д ашиглана
  bool _isNearBottom() {
    if (!_scrollCtrl.hasClients) return true;
    final dist = _scrollCtrl.position.maxScrollExtent - _scrollCtrl.position.pixels;
    return dist < 120;
  }

  String _fmtTime(String? t) { if (t == null) return ''; final dt = DateTime.tryParse(t)?.toLocal(); if (dt == null) return ''; return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}'; }
  /// Огноог "Өнөөдөр / Өчигдөр / YYYY/MM/DD" хэлбэрт хөрвүүлнэ.
  /// 24 цагийн зөрүүгээр биш, тухайн ӨДРИЙН ХИЛИЙГ үндэслэн харьцуулна
  /// — ингэснээр өчигдөр 23:00 явсан мессеж "Өчигдөр" гэж зөв харагдана.
  String _fmtDate(String? t) {
    if (t == null) return '';
    final dt = DateTime.tryParse(t)?.toLocal();
    if (dt == null) return '';
    final now      = DateTime.now();
    final today    = DateTime(now.year, now.month, now.day);
    final msgDay   = DateTime(dt.year, dt.month, dt.day);
    final daysDiff = today.difference(msgDay).inDays;
    if (daysDiff == 0) return 'Өнөөдөр';
    if (daysDiff == 1) return 'Өчигдөр';
    return '${dt.year}/${dt.month.toString().padLeft(2,'0')}/${dt.day.toString().padLeft(2,'0')}';
  }

  String _statusText() {
    if (widget.isGroup) return 'Группын чат';
    if (widget.isOnline) return 'Онлайн';
    // last seen from last message time
    return 'Оффлайн';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    final statusText = _statusText();
    final isActuallyOnline = widget.isOnline;

    return Scaffold(
      backgroundColor: c.bgDark,
      appBar: AppBar(
        backgroundColor: c.bgCard, elevation: 0, surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_rounded, color: c.textPrimary, size: 18), onPressed: () => Navigator.pop(context)),
        titleSpacing: 0,
        title: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: widget.isGroup ? c.primary : null,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: c.primary.withOpacity(0.3), blurRadius: 8)],
            ),
            child: ClipOval(
              child: widget.isGroup
                  ? const Center(child: Icon(Icons.group_rounded, color: Colors.white, size: 20))
                  : buildUserAvatar(
                      avatarUrl: widget.avatarUrl,
                      initials: widget.initials,
                      fallbackColor: c.primary,
                      size: 40,
                      themeColors: c,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.name, style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            Row(children: [
              if (isActuallyOnline || widget.isGroup) ...[
                Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF2DB87A), shape: BoxShape.circle)),
                const SizedBox(width: 5),
              ],
              Text(statusText,
                style: TextStyle(
                  color: (isActuallyOnline || widget.isGroup) ? const Color(0xFF2DB87A) : c.textMuted,
                  fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ])),
        ]),
        actions: [
          // ── Дуудлага товч ──────────────────────────────
          GestureDetector(
            onTap: () => _showCallDialog(false),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
              width: 42, height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [c.primary.withOpacity(0.9), c.accent.withOpacity(0.8)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: c.primary.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.call_rounded, color: Colors.white, size: 20),
            ),
          ),
          // ── Видео дуудлага товч ─────────────────────────
          GestureDetector(
            onTap: () => _showCallDialog(true),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
              width: 42, height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [c.accent.withOpacity(0.8), c.primary.withOpacity(0.9)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: c.accent.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(children: [
        Column(children: [
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: c.primary, strokeWidth: 2))
                : GestureDetector(
                    onTap: () { if (_showMediaMenu) { setState(() => _showMediaMenu = false); _mediaAnimCtrl.reverse(); } },
                    child: ListView.builder(
                      controller: _scrollCtrl, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final showDate = i == 0 || _fmtDate(_messages[i]['created_at']) != _fmtDate(_messages[i-1]['created_at']);
                        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          if (showDate) _buildDateDivider(_fmtDate(_messages[i]['created_at'] as String?), c),
                          _buildBubble(_messages[i], c),
                        ]);
                      },
                    ),
                  ),
          ),
          _buildInputBar(c, context),
        ]),

        // Scroll-to-bottom floating button — дээр гүйлгэсэн үед л харагдана
        if (_showScrollToBottom)
          Positioned(
            right: 16,
            bottom: 80, // input bar-аас дээгүүр
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: GestureDetector(
                key: ValueKey(_newMessageCount),
                onTap: () {
                  _scrollToBottom();
                  setState(() {
                    _showScrollToBottom = false;
                    _newMessageCount = 0;
                  });
                },
                child: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: c.bgCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.border.withOpacity(0.25)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Stack(clipBehavior: Clip.none, children: [
                    Center(child: Icon(Icons.keyboard_arrow_down_rounded, color: c.textPrimary, size: 26)),
                    if (_newMessageCount > 0)
                      Positioned(
                        top: -2, right: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          decoration: BoxDecoration(
                            gradient: c.accentGradient,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.bgCard, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              _newMessageCount > 99 ? '99+' : '$_newMessageCount',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            ),
          ),

        if (_showMediaMenu)
          Positioned(
            left: 14, bottom: MediaQuery.of(context).viewInsets.bottom + 76,
            child: ScaleTransition(scale: _mediaAnim, alignment: Alignment.bottomLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                decoration: BoxDecoration(color: c.bgCard, borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 28, offset: const Offset(0, 8))],
                  border: Border.all(color: c.border.withOpacity(0.15))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _mediaBtn(c, Icons.image_rounded, const Color(0xFF4F8EF7), 'Зураг', _pickImage),
                  const SizedBox(width: 22),
                  _mediaBtn(c, Icons.attach_file_rounded, const Color(0xFFF5A623), 'Файл', _pickFile),
                  const SizedBox(width: 22),
                  _mediaBtn(c, _isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded, _isRecording ? const Color(0xFFE8547A) : const Color(0xFF2DB87A), _isRecording ? 'Зогсоох' : 'Дуу', _toggleRecording),
                ]),
              ),
            ),
          ),
      ]),
    );
  }

  // content текстээс дуудлагын төрлийг илрүүлнэ
  String _detectCallType(String content) {
    if (content.contains('(алдсан)') && content.contains('Видео')) return 'missed_video_call';
    if (content.contains('(алдсан)')) return 'missed_call';
    if (content.contains('📹') || content.contains('Видео дуудлага')) return 'video_call';
    if (content.contains('📞') || content.contains('Дуу дуудлага')) return 'call';
    return '';
  }

  Widget _mediaBtn(ThemeColors c, IconData icon, Color color, String label, VoidCallback onTap) =>
      GestureDetector(onTap: onTap, child: Column(children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.25)), boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 12)]),
          child: Icon(icon, color: color, size: 26)),
        const SizedBox(height: 7),
        Text(label, style: TextStyle(color: c.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
      ]));

  Widget _buildDateDivider(String label, ThemeColors c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(children: [
      Expanded(child: Divider(color: c.border.withOpacity(0.2), thickness: 0.5)),
      Container(margin: const EdgeInsets.symmetric(horizontal: 10), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: TextStyle(color: c.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
      Expanded(child: Divider(color: c.border.withOpacity(0.2), thickness: 0.5)),
    ]),
  );

  Widget _buildBubble(Map<String, dynamic> msg, ThemeColors c) {
    final isMe     = msg['sender_id'] == _myUid;
    final content  = msg['content']    as String? ?? '';
    final mediaType = msg['media_type'] as String? ?? _detectCallType(content);

    // Дуудлагын мессеж бол тусгай bubble
    if (mediaType == 'call' || mediaType == 'video_call' ||
        mediaType == 'missed_call' || mediaType == 'missed_video_call') {
      // ── Зүүн талд (нөгөө хүнээс ирсэн дуудлага) avatar нэмнэ.
      //   Мессеж/файлтай ижил визуал тогтолцоог call bubble дээр ч хэрэглэнэ.
      final callerNameForAvatar = widget.name;
      final callerAvatarForAvatar = widget.avatarUrl;
      final callBubbleWidget = CallBubble(
        msg: {...msg, 'media_type': mediaType},
        isMe: isMe, c: c,
        convId: widget.convId,
        myUid: _myUid ?? '',
        remoteUid: widget.otherUserId ?? '',
        remoteName: widget.name,
        remoteInitials: widget.initials,
        remoteAvatarUrl: widget.avatarUrl,
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: c.primary.withOpacity(0.2), blurRadius: 6)],
                ),
                child: ClipOval(
                  child: buildUserAvatar(
                    avatarUrl: callerAvatarForAvatar,
                    initials: callerNameForAvatar.isNotEmpty
                        ? callerNameForAvatar[0].toUpperCase()
                        : '?',
                    fallbackColor: c.primary.withOpacity(0.85),
                    size: 30,
                    themeColors: c,
                  ),
                ),
              ),
              const SizedBox(width: 7),
            ],
            Flexible(child: callBubbleWidget),
          ],
        ),
      );
    }
    final senderName   = _userNames[msg['sender_id']] ?? 'Хэрэглэгч';
    final senderAvatar = _userAvatars[msg['sender_id']];
    final time         = _fmtTime(msg['created_at'] as String?);
    final mediaUrl     = msg['media_url'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (!isMe) ...[
          // Sender avatar — icon, зураг эсвэл initials
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: c.primary.withOpacity(0.2), blurRadius: 6)],
            ),
            child: ClipOval(
              child: buildUserAvatar(
                avatarUrl: senderAvatar,
                initials: senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                fallbackColor: c.primary.withOpacity(0.85),
                size: 30,
                themeColors: c,
              ),
            ),
          ),
          const SizedBox(width: 7),
        ],
        Flexible(child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
          if (!isMe && widget.isGroup) Padding(padding: const EdgeInsets.only(left: 4, bottom: 3), child: Text(senderName, style: TextStyle(color: c.primary.withOpacity(0.85), fontSize: 11, fontWeight: FontWeight.w700))),
          GestureDetector(
            onTap: () {
              if (mediaType == 'image' && mediaUrl != null) {
                _openImageViewer(mediaUrl);
              } else if (mediaType == 'file' && mediaUrl != null) {
                _openExternalUrl(mediaUrl);
              }
            },
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: mediaType == 'image' ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe ? c.accentGradient : null, color: isMe ? null : c.bgCard,
                borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(isMe ? 18 : 4), bottomRight: Radius.circular(isMe ? 4 : 18)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(isMe ? 0.1 : 0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: mediaType == 'image' && mediaUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(isMe ? 18 : 4), bottomRight: Radius.circular(isMe ? 4 : 18)),
                      child: Image.network(mediaUrl, width: 200, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.broken_image_outlined, color: isMe ? Colors.white70 : c.textMuted, size: 20), const SizedBox(width: 8), Text('Зураг', style: TextStyle(color: isMe ? Colors.white : c.textPrimary))]))))
                  : mediaType == 'audio'
                      ? _AudioMessageBubble(mediaUrl: mediaUrl, isMe: isMe, c: c, fallbackLabel: content)
                      : mediaType == 'file'
                          ? _buildFileBubble(content, mediaUrl, isMe, c)
                          : Text(content, style: TextStyle(fontSize: 14, height: 1.45, color: isMe ? Colors.white : c.textPrimary)),
            ),
          ),
          const SizedBox(height: 3),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(time, style: TextStyle(color: c.textMuted, fontSize: 10)),
            if (isMe) ...[
              const SizedBox(width: 4),
              msg['_error'] == true
                  ? const Icon(Icons.error_outline_rounded, size: 13, color: Color(0xFFE8547A))
                  : msg['_pending'] == true
                      ? SizedBox(width: 13, height: 13, child: CircularProgressIndicator(color: c.primary.withOpacity(0.5), strokeWidth: 1.5))
                      : Icon(Icons.done_all_rounded, size: 13, color: c.primary.withOpacity(0.7)),
            ],
          ]),
        ])),
        if (isMe) const SizedBox(width: 2),
      ]),
    );
  }

  /// Файлын мессежийн bubble — нэр + хэмжээ + татах icon
  Widget _buildFileBubble(String content, String? url, bool isMe, ThemeColors c) {
    // content нь "📎 filename.ext" хэлбэртэй (_pickFile-аас)
    final fileName = content.replaceFirst(RegExp(r'^📎\s*'), '').trim();
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 38, height: 38, margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: (isMe ? Colors.white : c.primary).withOpacity(0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(_iconForExt(ext),
          color: isMe ? Colors.white : c.primary, size: 20),
      ),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(fileName.isEmpty ? 'Файл' : fileName,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: isMe ? Colors.white : c.textPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('Дарж нээх',
              style: TextStyle(
                fontSize: 11,
                color: (isMe ? Colors.white : c.textMuted).withOpacity(0.75))),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Icon(Icons.open_in_new_rounded,
        color: (isMe ? Colors.white : c.textMuted).withOpacity(0.7), size: 16),
    ]);
  }

  IconData _iconForExt(String ext) {
    if (['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'].contains(ext)) return Icons.image_rounded;
    if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) return Icons.movie_rounded;
    if (['mp3', 'wav', 'm4a', 'ogg', 'aac'].contains(ext)) return Icons.audio_file_rounded;
    if (ext == 'pdf') return Icons.picture_as_pdf_rounded;
    if (['doc', 'docx'].contains(ext)) return Icons.description_rounded;
    if (['xls', 'xlsx', 'csv'].contains(ext)) return Icons.table_chart_rounded;
    if (['ppt', 'pptx'].contains(ext)) return Icons.slideshow_rounded;
    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) return Icons.folder_zip_rounded;
    if (['txt', 'md', 'log'].contains(ext)) return Icons.text_snippet_rounded;
    return Icons.insert_drive_file_rounded;
  }

  /// Файл/линкийг гадны нээх (browser-р татах эсвэл харах)
  Future<void> _openExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файлыг нээж чадсангүй')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Алдаа: $e')));
    }
  }

  /// Зургийг бүтэн дэлгэцээр харах
  void _openImageViewer(String url) {
    Navigator.push(context, PageRouteBuilder(
      opaque: false, barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => _ImageViewerScreen(url: url),
    ));
  }

  Widget _buildInputBar(ThemeColors c, BuildContext ctx) => Container(
    padding: EdgeInsets.only(left: 10, right: 12, top: 10, bottom: MediaQuery.of(ctx).viewInsets.bottom + 12),
    decoration: BoxDecoration(color: c.bgCard, border: Border(top: BorderSide(color: c.border.withOpacity(0.1)))),
    child: _isRecording ? _buildRecordingBar(c) : _buildNormalBar(c),
  );

  Widget _buildNormalBar(ThemeColors c) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
    GestureDetector(
      onTap: _toggleMediaMenu,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42, height: 42, margin: const EdgeInsets.only(right: 8, bottom: 1),
        decoration: BoxDecoration(
          gradient: _showMediaMenu ? null : c.accentGradient,
          color: _showMediaMenu ? c.primary.withOpacity(0.12) : null,
          shape: BoxShape.circle,
          border: _showMediaMenu ? Border.all(color: c.primary.withOpacity(0.4)) : null,
          boxShadow: _showMediaMenu ? [] : [BoxShadow(color: c.primary.withOpacity(0.3), blurRadius: 10)],
        ),
        child: AnimatedRotation(duration: const Duration(milliseconds: 250), turns: _showMediaMenu ? 0.125 : 0,
          child: Icon(Icons.add_rounded, color: _showMediaMenu ? c.primary : Colors.white, size: 22)),
      ),
    ),
    Expanded(child: Container(
      constraints: const BoxConstraints(minHeight: 42, maxHeight: 120),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: c.border.withOpacity(0.2))),
      child: TextField(controller: _ctrl, style: TextStyle(fontSize: 14, color: c.textPrimary), onSubmitted: (_) => _send(), maxLines: null,
        decoration: InputDecoration(
          hintText: 'Мессеж бичих...',
          hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11))),
    )),
    const SizedBox(width: 8),
    GestureDetector(onTap: _sending ? null : _send,
      child: Container(width: 42, height: 42, margin: const EdgeInsets.only(bottom: 1),
        decoration: BoxDecoration(gradient: c.accentGradient, shape: BoxShape.circle, boxShadow: [BoxShadow(color: c.primary.withOpacity(0.3), blurRadius: 10)]),
        child: _sending ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded, color: Colors.white, size: 19))),
  ]);

  Widget _buildRecordingBar(ThemeColors c) {
    final mins = _recordElapsed.inMinutes.toString().padLeft(2, '0');
    final secs = (_recordElapsed.inSeconds % 60).toString().padLeft(2, '0');
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      // Cancel
      GestureDetector(
        onTap: _cancelRecording,
        child: Container(
          width: 42, height: 42, margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8547A).withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE8547A).withOpacity(0.4)),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE8547A), size: 22),
        ),
      ),
      // Waveform + time
      Expanded(
        child: Container(
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE8547A).withOpacity(0.4)),
          ),
          child: Row(children: [
            _RecPulseDot(),
            const SizedBox(width: 10),
            Expanded(child: _RecordingWaveform(color: c.primary)),
            const SizedBox(width: 10),
            Text('$mins:$secs',
              style: TextStyle(
                color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      // Stop & send
      GestureDetector(
        onTap: _stopAndSendRecording,
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            gradient: c.accentGradient,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: c.primary.withOpacity(0.3), blurRadius: 10)],
          ),
          child: const Icon(Icons.send_rounded, color: Colors.white, size: 19),
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════
// DOT PULSE
// ═══════════════════════════════════════════════════════════
class _DotPulse extends StatefulWidget {
  final int delay; final Color color;
  const _DotPulse({required this.delay, required this.color});
  @override State<_DotPulse> createState() => _DotPulseState();
}
class _DotPulseState extends State<_DotPulse> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl; late Animation<double> _anim;
  @override void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true); _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut); Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _ctrl.forward(); }); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: _anim, builder: (_, __) => Container(width: 7, height: 7, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withOpacity(0.35 + 0.65 * _anim.value))));
}

// ═══════════════════════════════════════════════════════════
// CALL SERVICE — call_logs table-ээр дамжуулна
// ═══════════════════════════════════════════════════════════
class CallService {
  static String signalChannel(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return 'webrtc_signal_${ids[0]}_${ids[1]}';
  }

  // call_logs-д insert хийж нөгөө талд мэдэгдэл явуулна
  static Future<String?> sendCallInvite({
    required String fromUid, required String toUid,
    required String fromName, required String convId, required bool isVideo,
  }) async {
    try {
      final row = await supabase.from('call_logs').insert({
        'caller_uid':  fromUid,
        'callee_uid':  toUid,
        'caller_name': fromName,
        'conv_id':     convId,
        'is_video':    isVideo,
        'status':      'ringing',
      }).select().single();
      debugPrint('Call invite sent: ${row['id']}');
      return row['id'] as String?;
    } catch (e) {
      debugPrint('sendCallInvite алдаа: $e');
      return null;
    }
  }

  // Дуудлагын статус шинэчлэх
  static Future<void> updateCallStatus(String callId, String status) async {
    try {
      await supabase.from('call_logs').update({'status': status}).eq('id', callId);
    } catch (e) {
      debugPrint('updateCallStatus алдаа: $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════
// INCOMING CALL SCREEN
// ═══════════════════════════════════════════════════════════
class IncomingCallScreen extends StatefulWidget {
  final String callId, callerUid, callerName, callerInitials, convId, myUid;
  final bool isVideo;
  final String? callerAvatarUrl; // 'icon:N', 'https://...' эсвэл null
  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.callerUid, required this.callerName,
    required this.callerInitials, required this.convId,
    required this.myUid, required this.isVideo,
    this.callerAvatarUrl,
  });
  @override State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  RealtimeChannel? _listenCh;
  bool _answered = false;
  final _ringEngine = _RingtoneEngine();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    _listenForCancel();
    _playRingTone();
    // Auto-decline after 30s
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && !_answered) _decline();
    });
  }

  Timer? _vibrateTimer;

  Future<void> _playRingTone() async {
    // 1) Vibration — Messenger маягийн "buzz buzz" pattern
    try {
      HapticFeedback.heavyImpact();
      _vibrateTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
        if (!mounted || _answered) return;
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_answered) HapticFeedback.heavyImpact();
        });
      });
    } catch (_) {}
    // 2) Сүлжээгүй ч ажилладаг program-аас үүсгэсэн ring tone
    try {
      await _ringEngine.startLoop(
        wav: _RingtoneEngine.incomingRingWav(),
        interval: const Duration(milliseconds: 2000),
      );
    } catch (e) { debugPrint('ring start алдаа: $e'); }
  }

  void _stopRingTone() {
    _vibrateTimer?.cancel(); _vibrateTimer = null;
    _ringEngine.stop();
  }

  void _listenForCancel() {
    final chName = CallService.signalChannel(widget.myUid, widget.callerUid);
    _listenCh = supabase.channel('${chName}_callee')
      ..onBroadcast(event: 'signal', callback: (payload) {
          final data = payload['data'] as Map<String, dynamic>?;
          if (data?['type'] == 'hangup' && data?['from'] == widget.callerUid) {
            if (mounted && !_answered) {
              _decline(missedCall: false); // caller таслав — missed биш
            }
          }
        })
      ..subscribe();
  }

  void _answer() {
    if (_answered) return;
    setState(() => _answered = true);
    _pulseCtrl.stop();
    _stopRingTone();
    CallService.updateCallStatus(widget.callId, 'answered');
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ThemeProvider>(),
        child: WebRtcCallScreen(
          callId:         widget.callId,
          convId:         widget.convId,
          myUid:          widget.myUid,
          remoteUid:      widget.callerUid,
          remoteName:     widget.callerName,
          remoteInitials: widget.callerInitials,
          remoteAvatarUrl: widget.callerAvatarUrl,
          isVideo:        widget.isVideo,
          isCaller:       false,
        ),
      ),
    ));
  }

  void _decline({bool missedCall = false}) {
    if (!mounted) return;
    _stopRingTone();
    CallService.updateCallStatus(widget.callId, 'missed');
    // ⚠️ Callee энд message insert хийхгүй — caller WebRtcCallScreen өөрөө
    // hangup хийгээд missed гэж log хийнэ. Үгүй бол DB-д давхардаж бичигдэнэ.
    Navigator.pop(context);
  }

  @override
  void dispose() { _stopRingTone(); _pulseCtrl.dispose(); _listenCh?.unsubscribe(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [

        // ── Blur/gradient background ─────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [const Color(0xFF0d0d2e), const Color(0xFF050510), Colors.black],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // ── Glow effect ──────────────────────────────────
        Positioned(top: -60, left: 0, right: 0,
          child: Center(child: Container(width: 300, height: 300,
            decoration: BoxDecoration(shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: c.primary.withOpacity(0.2), blurRadius: 100, spreadRadius: 30)])))),

        // ── Main content ─────────────────────────────────
        SafeArea(
          child: Column(children: [
            const SizedBox(height: 40),

            // Incoming label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
              child: Text(widget.isVideo ? 'Видео дуудлага ирлээ' : 'Дуудлага ирлээ',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
            ),
            const SizedBox(height: 32),

            // Pulse avatar
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Stack(alignment: Alignment.center, children: [
                // Outer pulse ring 2
                Container(width: 160 + _pulseAnim.value * 20, height: 160 + _pulseAnim.value * 20,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: c.primary.withOpacity(0.04 + _pulseAnim.value * 0.04))),
                // Outer pulse ring 1
                Container(width: 140 + _pulseAnim.value * 12, height: 140 + _pulseAnim.value * 12,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: c.primary.withOpacity(0.07 + _pulseAnim.value * 0.05))),
                // Avatar — caller-ийн profile зураг/icon/initials
                Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: widget.callerAvatarUrl == null ? c.accentGradient : null,
                    boxShadow: [BoxShadow(color: c.primary.withOpacity(0.45), blurRadius: 30, spreadRadius: 2)],
                  ),
                  child: ClipOval(
                    child: buildUserAvatar(
                      avatarUrl: widget.callerAvatarUrl,
                      initials: widget.callerInitials,
                      fallbackColor: c.primary,
                      size: 110,
                      themeColors: c,
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // Name
            Text(widget.callerName,
              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 10),
            Text(widget.isVideo ? '📹 Видео дуудлага' : '📞 Дуу дуудлага',
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 15, fontWeight: FontWeight.w500)),

            const Spacer(),

            // ── Secondary actions (Remind Me / Message) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _SecondaryAction(icon: Icons.alarm_rounded, label: 'Remind Me',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сануулга тохируулах')))),
                _SecondaryAction(icon: Icons.message_rounded, label: 'Мессеж',
                  onTap: () { _decline(); }),
              ]),
            ),
            const SizedBox(height: 32),

            // ── Decline / Accept buttons ──────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 52),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                // Decline
                _CallActionBtn(
                  icon: Icons.call_end_rounded,
                  label: 'Decline',
                  color: const Color(0xFFE8547A),
                  onTap: () => _decline(),
                ),
                // Accept
                _CallActionBtn(
                  icon: widget.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                  label: 'Accept',
                  color: const Color(0xFF2DB87A),
                  onTap: _answer,
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Secondary action (Remind Me / Message) ──────────────────
class _SecondaryAction extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _SecondaryAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(children: [
      Container(width: 52, height: 52,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.15))),
        child: Icon(icon, color: Colors.white, size: 22)),
      const SizedBox(height: 8),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );
}

// ── Call action button (Decline / Accept) ────────────────────
class _CallActionBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _CallActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(children: [
      Container(width: 70, height: 70,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6))]),
        child: Icon(icon, color: Colors.white, size: 30)),
      const SizedBox(height: 10),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════
// WEBRTC CALL SCREEN — Active call
// ═══════════════════════════════════════════════════════════
class WebRtcCallScreen extends StatefulWidget {
  final String callId, convId, myUid, remoteUid, remoteName, remoteInitials;
  final bool isVideo, isCaller;
  final bool remoteOnline;
  final String? remoteAvatarUrl; // 'icon:N', 'https://...', эсвэл null
  const WebRtcCallScreen({
    super.key,
    required this.callId,
    required this.convId, required this.myUid, required this.remoteUid,
    required this.remoteName, required this.remoteInitials,
    required this.isVideo, required this.isCaller,
    this.remoteOnline = false,
    this.remoteAvatarUrl,
  });
  @override State<WebRtcCallScreen> createState() => _WebRtcCallScreenState();
}

class _WebRtcCallScreenState extends State<WebRtcCallScreen> {
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  final _localRenderer  = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  RealtimeChannel? _sigChannel;

  bool _connected = false, _muted = false, _camOff = false, _speakerOn = true, _calling = true;
  Duration _elapsed = Duration.zero;
  DateTime? _startTime;
  Timer? _timer;
  final _callerRingEngine = _RingtoneEngine();

  // Metered.ca TURN credentials (clubhub project, free tier 500MB/mo)
  // Шинэ key хэрэгтэй бол: https://dashboard.metered.ca → TURN Server → Add Credential
  static const String _meteredUsername   = '40b3c9b2863ef919d7a26682';
  static const String _meteredCredential = 'TkYz4YDT7rVvUKrC';

  static const _iceServers = {
    'iceServers': [
      // STUN — шууд P2P холболт оролдоно
      {'urls': 'stun:stun.relay.metered.ca:80'},
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun.cloudflare.com:3478'},
      // TURN — NAT/firewall-ийн ард байгаа төхөөрөмжүүдэд relay хийнэ.
      // UDP 80, UDP 443, TCP 80, TCP 443, TLS 443 — firewall давах бүх port.
      {
        'urls': 'turn:global.relay.metered.ca:80',
        'username':   _meteredUsername,
        'credential': _meteredCredential,
      },
      {
        'urls': 'turn:global.relay.metered.ca:80?transport=tcp',
        'username':   _meteredUsername,
        'credential': _meteredCredential,
      },
      {
        'urls': 'turn:global.relay.metered.ca:443',
        'username':   _meteredUsername,
        'credential': _meteredCredential,
      },
      {
        'urls': 'turns:global.relay.metered.ca:443?transport=tcp',
        'username':   _meteredUsername,
        'credential': _meteredCredential,
      },
    ],
    'sdpSemantics':       'unified-plan',
    'iceCandidatePoolSize': 4,
  };

  @override
  void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await _setupPeerConnection();
    // Caller-ийн ring tone-ийг ХАМГИЙН ЭХЛЭЭД эхлүүлнэ — WebRTC audio session
    // байгуулагдахаас өмнө playback-ыг ажиллуулах нь чухал. await-аар хүлээгээд
    // ringtone бүрэн эхэлсний дараа WebRTC track-ийг нэмнэ.
    if (widget.isCaller) await _playCallerTone();
    // CRITICAL: local stream-ийг peer-д нэмсэний дараа л signaling эхлүүлнэ.
    // getUserMedia-аас өмнө WebRTC audio session тохируулахгүй — тэгвэл ringtone
    // тэр даруйд дуугарна. getUserMedia өөрөө audio session-ийг тохируулна.
    await _getLocalStream();
    if (!mounted) return;
    // Now configure WebRTC audio routing
    await _configureAudioSession();
    _subscribeSignaling();
    // Caller — DB-аас call_logs.status өөрчлөлтийг ажиглана (signaling алдагдсан ч ажиллана)
    _watchCallStatus();
  }

  Future<void> _configureAudioSession() async {
    try {
      // iOS: speaker, mic дуудлагын режимд оруулна
      await Helper.setAppleAudioConfiguration(AppleAudioConfiguration(
        appleAudioCategory: AppleAudioCategory.playAndRecord,
        appleAudioCategoryOptions: {
          AppleAudioCategoryOption.allowBluetooth,
          AppleAudioCategoryOption.defaultToSpeaker,
        },
        appleAudioMode: AppleAudioMode.voiceChat,
      ));
    } catch (e) { debugPrint('Apple audio config алдаа: $e'); }
    try {
      // Android: voice communication mode
      await Helper.setAndroidAudioConfiguration(AndroidAudioConfiguration(
        manageAudioFocus: true,
        androidAudioMode: AndroidAudioMode.inCommunication,
        androidAudioFocusMode: AndroidAudioFocusMode.gain,
        androidAudioStreamType: AndroidAudioStreamType.voiceCall,
        androidAudioAttributesUsageType: AndroidAudioAttributesUsageType.voiceCommunication,
        androidAudioAttributesContentType: AndroidAudioAttributesContentType.speech,
      ));
    } catch (e) { debugPrint('Android audio config алдаа: $e'); }
  }

  Future<void> _playCallerTone() async {
    // Online: хурдан, богино "ding-ding" — Messenger online ring (1.5с тутам)
    // Offline: удаан "BRR... BRR..." уламжлалт телефон pulse (2.2с тутам)
    final wav = widget.remoteOnline
        ? _RingtoneEngine.callerRingWav()
        : _RingtoneEngine.callerOfflineRingWav();
    final interval = widget.remoteOnline
        ? const Duration(milliseconds: 1500)
        : const Duration(milliseconds: 2200);
    try {
      await _callerRingEngine.startLoop(wav: wav, interval: interval);
    } catch (e) { debugPrint('caller ring алдаа: $e'); }
  }

  void _stopCallerTone() {
    _callerRingEngine.stop();
  }

  Future<void> _setupPeerConnection() async {
    _pc = await createPeerConnection(_iceServers);

    _pc!.onIceCandidate = (c) {
      if (c.candidate != null) {
        // Candidate type-аас ямар TURN/STUN ашиглаж байгааг тодруулна
        final cand = c.candidate ?? '';
        String typ = 'host';
        if (cand.contains('typ srflx')) typ = 'srflx (STUN)';
        else if (cand.contains('typ relay')) typ = 'relay (TURN) ✓';
        else if (cand.contains('typ prflx')) typ = 'prflx';
        debugPrint('[ICE-out] $typ: $cand');
        _sendSignal({'type': 'candidate', 'candidate': c.toMap()});
      }
    };

    _pc!.onIceGatheringState = (state) {
      debugPrint('[ICE] gathering: $state');
    };

    _pc!.onConnectionState = (state) {
      debugPrint('[PC] connection: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _startStatsLogging();
      }
    };


    _pc!.onIceConnectionState = (state) {
      debugPrint('ICE state: $state');
      if (!mounted) return;
      final connected = state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
                        state == RTCIceConnectionState.RTCIceConnectionStateCompleted;
      final hardFailed = state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
                         state == RTCIceConnectionState.RTCIceConnectionStateClosed;
      final transientDisconnect = state == RTCIceConnectionState.RTCIceConnectionStateDisconnected;
      setState(() {
        _connected = connected;
        _calling   = !connected && !hardFailed;
      });
      if (connected) {
        _stopCallerTone();
        // Хариулах үед хэдийн timer эхэлсэн байж болзошгүй — давхар нэмэхгүй
        _startTime ??= DateTime.now();
        _startTimer();
      }
      // Хатуу алдаанд шууд таслана
      if (hardFailed) { _hangup(); return; }
      // Disconnected нь түр зуурын байж болно — 5с-д сэргэхгүй бол таслана
      if (transientDisconnect) {
        Future.delayed(const Duration(seconds: 5), () {
          if (!mounted) return;
          if (!_connected) _hangup();
        });
      }
    };

    _pc!.onTrack = (event) {
      debugPrint('Remote track ирлээ: ${event.track.kind} streams=${event.streams.length}');
      if (!mounted) return;
      // Remote track-ийг шууд enabled болгоно (зарим төхөөрөмжид default off ирдэг)
      try { event.track.enabled = true; } catch (_) {}
      if (event.streams.isNotEmpty) {
        final stream = event.streams[0];
        // Stream-ийн бүх audio track-ийг enabled болгоно
        for (final t in stream.getAudioTracks()) {
          try { t.enabled = true; } catch (_) {}
        }
        setState(() => _remoteRenderer.srcObject = stream);
      }
    };

    _timer = Timer(Duration.zero, () {});
  }

  Timer? _statsTimer;

  void _startStatsLogging() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted || _pc == null) return;
      try {
        final stats = await _pc!.getStats();
        int audioBytesIn = 0, audioBytesOut = 0;
        int videoBytesIn = 0, videoBytesOut = 0;
        String? activeCandidatePair;
        for (final r in stats) {
          if (r.type == 'inbound-rtp') {
            final kind = r.values['kind'] ?? r.values['mediaType'];
            final bytes = (r.values['bytesReceived'] as num?)?.toInt() ?? 0;
            if (kind == 'audio') audioBytesIn = bytes;
            if (kind == 'video') videoBytesIn = bytes;
          } else if (r.type == 'outbound-rtp') {
            final kind = r.values['kind'] ?? r.values['mediaType'];
            final bytes = (r.values['bytesSent'] as num?)?.toInt() ?? 0;
            if (kind == 'audio') audioBytesOut = bytes;
            if (kind == 'video') videoBytesOut = bytes;
          } else if (r.type == 'candidate-pair' &&
              (r.values['nominated'] == true || r.values['state'] == 'succeeded')) {
            activeCandidatePair = '${r.values['localCandidateId']} ↔ ${r.values['remoteCandidateId']}';
          }
        }
        debugPrint('[STATS] audio=in:$audioBytesIn/out:$audioBytesOut '
                   'video=in:$videoBytesIn/out:$videoBytesOut pair=$activeCandidatePair');
      } catch (e) {
        debugPrint('[STATS] алдаа: $e');
      }
    });
  }

  Future<void> _attachLocalTracks(MediaStream stream) async {
    for (final track in stream.getTracks()) {
      track.enabled = true;
      try {
        final sender = await _pc!.addTrack(track, stream);
        debugPrint('[PC] track added: ${track.kind} id=${track.id}');
        // Видео track-д bitrate хязгаарлана (free TURN-д тохирно)
        if (track.kind == 'video') {
          try {
            final params = sender.parameters;
            params.encodings ??= [];
            if (params.encodings!.isEmpty) {
              params.encodings!.add(RTCRtpEncoding(
                maxBitrate:  300 * 1000, // 300 kbps — Messenger-ийн ердийн video bitrate
                maxFramerate: 20,
              ));
            } else {
              for (final enc in params.encodings!) {
                enc.maxBitrate  = 300 * 1000;
                enc.maxFramerate = 20;
              }
            }
            await sender.setParameters(params);
            debugPrint('[PC] video bitrate limited to 300kbps');
          } catch (e) {
            debugPrint('[PC] setParameters алдаа: $e');
          }
        }
      } catch (e) {
        debugPrint('[PC] addTrack алдаа: $e');
      }
    }
  }

  Future<void> _getLocalStream() async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation':  true,
          'noiseSuppression':  true,
          'autoGainControl':   true,
        },
        // Бага resolution + frame rate — free TURN-ийн bandwidth-д тохирно
        // Camera яг 640x480 дэмждэггүй ч хүлээн авахаар "ideal" ашиглана
        'video': widget.isVideo ? {
          'facingMode': 'user',
          'width':     {'ideal': 480, 'max': 640},
          'height':    {'ideal': 360, 'max': 480},
          'frameRate': {'ideal': 20, 'max': 24},
        } : false,
      });
      debugPrint('[STREAM] audio tracks: ${_localStream!.getAudioTracks().length} '
                 'video tracks: ${_localStream!.getVideoTracks().length}');
      _localRenderer.srcObject = _localStream;
      await _attachLocalTracks(_localStream!);
      // Speaker default-аар асаалттай — хэрэглэгч хэрэгцээтэй бол earpiece руу шилжүүлж болно
      try { await Helper.setSpeakerphoneOn(true); } catch (_) {}
      if (mounted) setState(() => _speakerOn = true);
    } catch (e) {
      debugPrint('getUserMedia алдаа: $e');
      // Зөвхөн аудио оролдоно (видео татгалзсан бол)
      if (widget.isVideo) {
        try {
          _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
          _localRenderer.srcObject = _localStream;
          await _attachLocalTracks(_localStream!);
          try { await Helper.setSpeakerphoneOn(true); } catch (_) {}
          if (mounted) setState(() => _speakerOn = true);
          return;
        } catch (_) {}
      }
      // Микрофон ч татгалзсан — зөвшөөрлийн заавар харуулна
      if (mounted) {
        _showPermissionGuide();
      }
    }
  }

  Future<void> _toggleSpeaker() async {
    final next = !_speakerOn;
    try { await Helper.setSpeakerphoneOn(next); } catch (_) {}
    if (mounted) setState(() => _speakerOn = next);
  }

  void _showPermissionGuide() {
    final c = context.read<ThemeProvider>().colors;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: c.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(color: const Color(0xFFE8547A).withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.mic_off_rounded, color: Color(0xFFE8547A), size: 22)),
          const SizedBox(width: 12),
          Text('Микрофон зөвшөөрөл', style: TextStyle(color: c.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Дуудлага хийхийн тулд микрофон ашиглах зөвшөөрөл шаардлагатай.', style: TextStyle(color: c.textMuted, fontSize: 14, height: 1.5)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Chrome дээр зөвшөөрөл өгөх:', style: TextStyle(color: c.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _permStep('1', 'Хаягийн мөрний зүүн талд 🔒 дарна'),
              _permStep('2', '"Site settings" сонгоно'),
              _permStep('3', 'Microphone → "Allow" болгоно'),
              _permStep('4', 'Хуудсыг refresh хийнэ'),
            ]),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: Text('Буцах', style: TextStyle(color: c.textMuted))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Дахин оролдоно
              await _getLocalStream();
            },
            style: ElevatedButton.styleFrom(backgroundColor: c.primary),
            child: const Text('Дахин оролдох')),
        ],
      ),
    );
  }

  Widget _permStep(String num, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 20, height: 20, decoration: BoxDecoration(color: const Color(0xFF6c63ff).withOpacity(0.2), shape: BoxShape.circle),
        child: Center(child: Text(num, style: const TextStyle(color: Color(0xFF6c63ff), fontSize: 11, fontWeight: FontWeight.w700)))),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4))),
    ]),
  );

  bool _offerSent = false;
  bool _remoteDescSet = false;
  bool _remoteAnswered = false;
  final List<RTCIceCandidate> _pendingCandidates = [];
  RealtimeChannel? _callStatusCh;

  Future<void> _flushPendingCandidates() async {
    for (final c in _pendingCandidates) {
      try { await _pc!.addCandidate(c); } catch (e) { debugPrint('addCandidate (buffered) алдаа: $e'); }
    }
    _pendingCandidates.clear();
  }

  /// Caller дээр "Дуудаж байна..." → "Холбогдож байна..." руу шилжүүлж,
  /// caller tone-ыг зогсоож, timer-ийг эхлүүлнэ. Олон газраас дуудагддаг тул
  /// дотор нь idempotent (нэг л удаа ажилладаг).
  void _markRemoteAnswered() {
    if (_remoteAnswered || !mounted) return;
    setState(() => _remoteAnswered = true);
    _stopCallerTone();
    _startTime ??= DateTime.now();
    _startTimer();
    debugPrint('[CALL] callee хариуллаа — Холбогдож байна...');
  }

  /// Caller — DB-ээс call_logs.status өөрчлөлтийг сонсоно. Realtime broadcast
  /// алдагдсан ч DB ямагт source of truth учир callee хариулсан мөчид УИ
  /// заавал шинэчлэгдэнэ.
  void _watchCallStatus() {
    if (!widget.isCaller || widget.callId.isEmpty) return;
    _callStatusCh = supabase
        .channel('call_status_${widget.callId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public', table: 'call_logs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id', value: widget.callId,
          ),
          callback: (payload) {
            final status = payload.newRecord['status'] as String?;
            debugPrint('[CALL] DB status=$status');
            if (status == 'answered') _markRemoteAnswered();
          })
        .subscribe();
  }

  void _subscribeSignaling() {
    final chName = CallService.signalChannel(widget.myUid, widget.remoteUid);
    debugPrint('Signal channel: $chName isCaller=${widget.isCaller}');
    _sigChannel = supabase.channel(chName)
      ..onBroadcast(event: 'signal', callback: (payload) async {
          final data = payload['data'] as Map<String, dynamic>?;
          if (data == null || data['from'] == widget.myUid) return;
          final type = data['type'] as String?;
          debugPrint('Signal received: $type from ${data['from']}');
          try {
            if (type == 'ready') {
              // Callee бэлэн боллоо — caller offer явуулна. Мөн "ready" нь callee
              // хариулсан гэдгийг харуулна → "Холбогдож байна..." руу шилжинэ.
              if (widget.isCaller) {
                _markRemoteAnswered();
                if (!_offerSent) {
                  _offerSent = true;
                  await _createOffer();
                }
              }
            } else if (type == 'offer') {
              await _pc!.setRemoteDescription(RTCSessionDescription(data['sdp'] as String, 'offer'));
              _remoteDescSet = true;
              await _flushPendingCandidates();
              final ans = await _pc!.createAnswer({'offerToReceiveAudio': 1, 'offerToReceiveVideo': widget.isVideo ? 1 : 0});
              await _pc!.setLocalDescription(ans);
              _sendSignal({'type': 'answer', 'sdp': ans.sdp});
              debugPrint('Answer явуулсан');
            } else if (type == 'answer') {
              await _pc!.setRemoteDescription(RTCSessionDescription(data['sdp'] as String, 'answer'));
              _remoteDescSet = true;
              await _flushPendingCandidates();
              _markRemoteAnswered();
              debugPrint('Answer хүлээн авсан');
            } else if (type == 'candidate') {
              final cd = data['candidate'] as Map<String, dynamic>;
              final candidate = RTCIceCandidate(
                cd['candidate']    as String?,
                cd['sdpMid']       as String?,
                cd['sdpMLineIndex'] as int?,
              );
              if (_remoteDescSet) {
                await _pc!.addCandidate(candidate);
              } else {
                // Remote description суугаагүй байгаа — буфферт хадгалж дараа нэмнэ
                _pendingCandidates.add(candidate);
              }
            } else if (type == 'hangup') {
              _hangup(remote: true);
            }
          } catch (e) { debugPrint('Signal алдаа: $e'); }
        })
      ..subscribe((status, err) async {
          debugPrint('Signal channel status: $status err=$err');
          if (status != RealtimeSubscribeStatus.subscribed) return;

          if (widget.isCaller) {
            // Callee-аас "ready" хүлээх боловч хариу 4с дотор ирэхгүй бол шууд offer
            // явуулна (race-аас сэргийлэх backup).
            await Future.delayed(const Duration(seconds: 4));
            if (mounted && !_offerSent) {
              _offerSent = true;
              await _createOffer();
            }
          } else {
            // Callee — channel-д нэгдэнгүүт бэлэн дохио хэд хэдэн удаа явуулна.
            // Caller өмнөх дохиог алдсан байж болзошгүй (broadcast late join).
            _sendSignal({'type': 'ready'});
            // Хариулсан гэж бүртгэгдсэн тул timer-ийг шууд эхлүүлнэ (Messenger маяг)
            if (mounted) {
              setState(() => _remoteAnswered = true);
              _startTime ??= DateTime.now();
              _startTimer();
            }
            for (int i = 1; i <= 4; i++) {
              await Future.delayed(const Duration(seconds: 1));
              if (!mounted) return;
              _sendSignal({'type': 'ready'});
            }
          }
        });
  }

  Future<void> _createOffer() async {
    try {
      final offer = await _pc!.createOffer({'offerToReceiveAudio': 1, 'offerToReceiveVideo': widget.isVideo ? 1 : 0});
      await _pc!.setLocalDescription(offer);
      _sendSignal({'type': 'offer', 'sdp': offer.sdp});
      debugPrint('Offer явуулсан');
    } catch (e) { debugPrint('Offer алдаа: $e'); }
  }

  void _sendSignal(Map<String, dynamic> data) =>
      _sigChannel?.sendBroadcastMessage(event: 'signal', payload: {'data': {...data, 'from': widget.myUid}});

  void _startTimer() {
    _timer?.cancel();
    _startTime ??= DateTime.now();
    // Шууд бие даасан wallclock timer — _connected эсвэл _remoteAnswered үед ажиллана
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_startTime == null) return;
      setState(() => _elapsed = DateTime.now().difference(_startTime!));
    });
  }

  void _toggleMute() {
    _localStream?.getAudioTracks().forEach((t) => t.enabled = _muted);
    setState(() => _muted = !_muted);
  }

  void _toggleCamera() {
    _localStream?.getVideoTracks().forEach((t) => t.enabled = _camOff);
    setState(() => _camOff = !_camOff);
  }

  Future<void> _hangup({bool remote = false}) async {
    _timer?.cancel();
    if (!remote) _sendSignal({'type': 'hangup'});

    // ⚠️ ЗӨВХӨН caller дуудлагын bubble-ыг үүсгэнэ — давхардлаас сэргийлэх.
    // Callee хэзээ ч `messages` table-д insert хийхгүй.
    if (widget.isCaller) {
      try {
        if (_connected) {
          // Холбогдсон → үргэлжилсэн хугацаа
          final dur  = _elapsed.inSeconds;
          final mins = (dur ~/ 60).toString().padLeft(2, '0');
          final secs = (dur % 60).toString().padLeft(2, '0');
          final label = widget.isVideo ? '📹 Видео дуудлага' : '📞 Дуу дуудлага';
          await supabase.from('messages').insert({
            'conversation_id': widget.convId,
            'sender_id':       widget.myUid,
            'content':         '$label ($mins:$secs)',
            'media_type':      widget.isVideo ? 'video_call' : 'call',
          });
        } else {
          // Холбогдоогүй ч callee хариулсан байж болно — call_logs шалгана
          String? logStatus;
          try {
            final log = await supabase.from('call_logs').select('status').eq('id', widget.callId).maybeSingle();
            logStatus = log?['status'] as String?;
          } catch (_) {}

          if (logStatus == 'answered') {
            final label = widget.isVideo ? '📹 Видео дуудлага' : '📞 Дуу дуудлага';
            await supabase.from('messages').insert({
              'conversation_id': widget.convId,
              'sender_id':       widget.myUid,
              'content':         '$label (холбогдсонгүй)',
              'media_type':      widget.isVideo ? 'video_call' : 'call',
            });
          } else {
            await supabase.from('messages').insert({
              'conversation_id': widget.convId,
              'sender_id':       widget.myUid,
              'content':         widget.isVideo ? '📹 Видео дуудлага (алдсан)' : '📞 Дуу дуудлага (алдсан)',
              'media_type':      widget.isVideo ? 'missed_video_call' : 'missed_call',
            });
          }
        }
      } catch (e) {
        debugPrint('Дуудлага bubble алдаа: $e');
      }
    }

    await _localStream?.dispose();
    await _pc?.close();
    _sigChannel?.unsubscribe();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statsTimer?.cancel();
    _stopCallerTone();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _localStream?.dispose();
    _pc?.close();
    _sigChannel?.unsubscribe();
    _callStatusCh?.unsubscribe();
    super.dispose();
  }

  String _fmtElapsed() => '${(_elapsed.inMinutes).toString().padLeft(2,'0')}:${(_elapsed.inSeconds % 60).toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeProvider>().colors;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [

        // Background — Remote video байсан даруйд харуулна (ICE дуусахыг хүлээхгүй)
        widget.isVideo && _remoteRenderer.srcObject != null
            ? RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [const Color(0xFF0a0a20), Colors.black])),
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: _calling ? 108 : 96, height: _calling ? 108 : 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Avatar байхгүй бол default gradient харуулна
                      gradient: widget.remoteAvatarUrl == null ? c.accentGradient : null,
                      boxShadow: [BoxShadow(color: c.primary.withOpacity(_calling ? 0.45 : 0.25), blurRadius: _calling ? 48 : 20)],
                    ),
                    child: ClipOval(
                      child: buildUserAvatar(
                        avatarUrl: widget.remoteAvatarUrl,
                        initials: widget.remoteInitials,
                        fallbackColor: c.primary,
                        size: _calling ? 108 : 96,
                        themeColors: c,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(widget.remoteName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Text(
                    _connected
                        ? _fmtElapsed()
                        : _remoteAnswered
                            ? 'Холбогдож байна...'
                            : (_calling ? 'Дуудаж байна...' : 'Холбогдож байна...'),
                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 15, fontWeight: FontWeight.w500)),
                ])),
              ),

        // Local PIP video
        if (widget.isVideo && _localStream != null)
          Positioned(top: 60, right: 16,
            child: Container(width: 96, height: 136,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.3))),
              child: ClipRRect(borderRadius: BorderRadius.circular(12),
                child: RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)))),

        // Top bar
        Positioned(top: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.65), Colors.transparent])),
            child: Row(children: [
              GestureDetector(onTap: _hangup,
                child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 16))),
              const Spacer(),
              Text(widget.isVideo ? 'Видео дуудлага' : 'Дуудлага',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(), const SizedBox(width: 36),
            ]),
          ),
        ),

        // Controls
        Positioned(bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 50),
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.88), Colors.transparent])),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _CtrlBtn(icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded, label: _muted ? 'Нэм' : 'Хаа', color: _muted ? const Color(0xFFE8547A) : Colors.white, active: _muted, onTap: _toggleMute),
                const SizedBox(width: 18),
                if (widget.isVideo) ...[
                  _CtrlBtn(icon: _camOff ? Icons.videocam_off_rounded : Icons.videocam_rounded, label: _camOff ? 'Нэм' : 'Хаа', color: _camOff ? const Color(0xFFE8547A) : Colors.white, active: _camOff, onTap: _toggleCamera),
                  const SizedBox(width: 18),
                  _CtrlBtn(icon: Icons.flip_camera_ios_rounded, label: 'Эргүүл', color: Colors.white, active: false, onTap: () { if (_localStream?.getVideoTracks().isNotEmpty == true) Helper.switchCamera(_localStream!.getVideoTracks().first); }),
                  const SizedBox(width: 18),
                ],
                _CtrlBtn(icon: _speakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded, label: _speakerOn ? 'Чанга' : 'Чихэвч', color: Colors.white, active: _speakerOn, onTap: _toggleSpeaker),
              ]),
              const SizedBox(height: 30),
              GestureDetector(onTap: _hangup,
                child: Container(width: 70, height: 70,
                  decoration: BoxDecoration(color: const Color(0xFFE8547A), shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFFE8547A).withOpacity(0.4), blurRadius: 22)]),
                  child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32))),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CALL BUBBLE WIDGET — чатны дуудлагын мессеж
// ═══════════════════════════════════════════════════════════
class CallBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isMe;
  final ThemeColors c;
  final String convId, myUid, remoteUid, remoteName, remoteInitials;
  final String? remoteAvatarUrl;

  const CallBubble({
    super.key,
    required this.msg, required this.isMe, required this.c,
    required this.convId, required this.myUid, required this.remoteUid,
    required this.remoteName, required this.remoteInitials,
    this.remoteAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final type     = msg['media_type'] as String? ?? '';
    final content  = msg['content']    as String? ?? '';
    final time     = _fmtTime(msg['created_at'] as String?);
    final isMissed = type.contains('missed');
    final isVideo  = type.contains('video');

    Future<void> callAgain() async {
      final me = await supabase.from('users').select('full_name').eq('id', myUid).single();
      final fromName = me['full_name'] as String? ?? 'Хэрэглэгч';
      final callId = await CallService.sendCallInvite(
        fromUid: myUid, toUid: remoteUid,
        fromName: fromName, convId: convId, isVideo: isVideo,
      );
      if (!context.mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(value: context.read<ThemeProvider>(),
          child: WebRtcCallScreen(
            callId: callId ?? '', convId: convId, myUid: myUid,
            remoteUid: remoteUid, remoteName: remoteName,
            remoteInitials: remoteInitials,
            remoteAvatarUrl: remoteAvatarUrl,
            isVideo: isVideo, isCaller: true)),
      ));
    }

    // ─── Bubble color & icon: алдсан бол улаан, хариулсан бол саарал ───
    final accent       = isMissed ? const Color(0xFFE8547A) : c.textPrimary;
    final iconBg       = isMissed
        ? const Color(0xFFE8547A).withOpacity(0.18)
        : c.surface;
    final bubbleBg     = isMissed
        ? const Color(0xFFE8547A).withOpacity(0.12)
        : c.bgCard;
    final borderColor  = isMissed
        ? const Color(0xFFE8547A).withOpacity(0.28)
        : c.border.withOpacity(0.2);
    final IconData icon = isMissed
        ? (isVideo ? Icons.videocam_off_rounded : Icons.phone_missed_rounded)
        : (isVideo ? Icons.videocam_rounded     : Icons.call_rounded);

    final title = isMissed
        ? (isVideo ? 'Missed video call' : 'Missed voice call')
        : (isVideo ? 'Video call'        : 'Voice call');

    final subtitle = isMissed
        ? 'Tap to call back'
        : _formatDurationOrFailed(content);

    return GestureDetector(
      onTap: callAgain,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: bubbleBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
              const SizedBox(height: 2),
              Text(subtitle,
                style: TextStyle(fontSize: 11, color: accent.withOpacity(0.7))),
            ],
          ),
          const SizedBox(width: 16),
          Text(time, style: TextStyle(fontSize: 10, color: c.textMuted)),
        ]),
      ),
    );
  }

  /// "📹 Видео дуудлага (12:34)" → "12 min" / "(холбогдсонгүй)" → "Failed"
  String _formatDurationOrFailed(String content) {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(content);
    if (match == null) return '';
    final inside = match.group(1)!.trim();
    if (inside.contains('холбогдсонгүй')) return 'Failed to connect';
    final parts = inside.split(':');
    if (parts.length == 2) {
      final mm = int.tryParse(parts[0]) ?? 0;
      final ss = int.tryParse(parts[1]) ?? 0;
      if (mm == 0) return '$ss sec';
      if (ss == 0) return '$mm min';
      return '$mm min $ss sec';
    }
    return inside;
  }

  String _fmtTime(String? t) {
    if (t == null) return ''; final dt = DateTime.tryParse(t)?.toLocal(); if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

}

// ─────────────────────────────────────────────────────────────
// CTRL BUTTON
// ─────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────
// IMAGE VIEWER — зургийг бүтэн дэлгэцээр харах
// ─────────────────────────────────────────────────────────────
class _ImageViewerScreen extends StatelessWidget {
  final String url;
  const _ImageViewerScreen({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.8, maxScale: 4.0,
              child: Image.network(url, fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator(color: Colors.white)),
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64))),
            ),
          ),
          // Close товч
          Positioned(
            top: MediaQuery.of(context).padding.top + 8, left: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  final bool active; final VoidCallback onTap;
  const _CtrlBtn({required this.icon, required this.label, required this.color, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(children: [
      Container(width: 54, height: 54,
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.25) : Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: active ? color.withOpacity(0.4) : Colors.white.withOpacity(0.15)),
        ),
        child: Icon(icon, color: color, size: 24)),
      const SizedBox(height: 6),
      Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────
// INCOMING CALL LISTENER — апп даяар идэвхтэй global listener.
// AuthWrapper-аар бүх authenticated дэлгэцийг ороож ашиглана.
// ─────────────────────────────────────────────────────────────
class IncomingCallListener extends StatefulWidget {
  final Widget child;
  const IncomingCallListener({super.key, required this.child});

  @override
  State<IncomingCallListener> createState() => _IncomingCallListenerState();
}

class _IncomingCallListenerState extends State<IncomingCallListener> {
  RealtimeChannel? _ch;
  String? _watchedUid;
  String? _activeCallId; // одоо нээлттэй байгаа incoming dialog-ын ID
  Timer? _retryTimer;
  Timer? _pollTimer;
  String _lastSeenAt = DateTime.now().toUtc().toIso8601String();

  @override
  void initState() {
    super.initState();
    _start();
    // Auth state өөрчлөгдөхөд listener дахин эхлүүлнэ
    supabase.auth.onAuthStateChange.listen((_) {
      _start();
    });
  }

  Future<void> _showIncoming({
    required String callId,
    required String fromUid,
    required String fromName,
    required String convId,
    required bool isVideo,
  }) async {
    if (_activeCallId == callId) return;
    _activeCallId = callId;

    // Caller-ийн avatar-ыг DB-аас авна — ringing screen дээр харуулна
    String? callerAvatar;
    try {
      final u = await supabase.from('users')
          .select('avatar_url').eq('id', fromUid).maybeSingle();
      final av = u?['avatar_url'] as String?;
      if (av != null && av.isNotEmpty) callerAvatar = av;
    } catch (_) {}

    if (!mounted) { _activeCallId = null; return; }
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ThemeProvider>(),
        child: IncomingCallScreen(
          callId:           callId,
          callerUid:        fromUid,
          callerName:       fromName,
          callerInitials:   fromName.isNotEmpty ? fromName[0].toUpperCase() : '?',
          callerAvatarUrl:  callerAvatar,
          convId:           convId,
          myUid:            _watchedUid!,
          isVideo:          isVideo,
        ),
      ),
    )).then((_) => _activeCallId = null);
  }

  void _start() {
    final uid = supabase.auth.currentUser?.id;
    if (uid == _watchedUid) return; // ижил уид — өөрчлөлт алга
    _ch?.unsubscribe();
    _ch = null;
    _pollTimer?.cancel();
    _watchedUid = uid;
    if (uid == null) return;

    _lastSeenAt = DateTime.now().toUtc().toIso8601String();

    _ch = supabase
        .channel('incoming_calls_$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'call_logs',
          callback: (payload) {
            if (!mounted) return;
            final row = payload.newRecord;
            if (row['callee_uid'] != uid) return;

            final callId   = row['id']          as String?;
            final fromUid  = row['caller_uid']  as String?;
            final fromName = row['caller_name'] as String? ?? 'Хэрэглэгч';
            final convId   = row['conv_id']     as String?;
            final isVideo  = row['is_video']    as bool? ?? false;
            final status   = row['status']      as String?;

            debugPrint('[IncomingCallListener] Call: $callId from $fromName status=$status');
            if (fromUid == null || convId == null || callId == null) return;
            if (status != 'ringing') return;

            // Cursor шинэчилнэ
            final ts = row['created_at'] as String?;
            if (ts != null) _lastSeenAt = ts;

            _showIncoming(
              callId: callId, fromUid: fromUid, fromName: fromName,
              convId: convId, isVideo: isVideo,
            );
          },
        )
        .subscribe((status, err) {
          debugPrint('[IncomingCallListener] $status err=$err');
          if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            _retryTimer?.cancel();
            _retryTimer = Timer(const Duration(seconds: 5), () {
              if (mounted) {
                _watchedUid = null;
                _start();
              }
            });
          }
        });

    // Polling fallback — Supabase realtime publication дутуу/үймэгдсэн ч
    // дуудлага алдагдахгүй байх нэмэлт давхарга. 2 секунд тутамд шинэ ringing
    // call-ыг шалгана.
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted || _activeCallId != null) return;
      final myUid = _watchedUid;
      if (myUid == null) return;
      try {
        final rows = await supabase
            .from('call_logs')
            .select()
            .eq('callee_uid', myUid)
            .eq('status', 'ringing')
            .gt('created_at', _lastSeenAt)
            .order('created_at', ascending: false)
            .limit(1);
        if (rows.isEmpty) return;
        final row = Map<String, dynamic>.from(rows.first as Map);
        final callId   = row['id']          as String?;
        final fromUid  = row['caller_uid']  as String?;
        final fromName = row['caller_name'] as String? ?? 'Хэрэглэгч';
        final convId   = row['conv_id']     as String?;
        final isVideo  = row['is_video']    as bool? ?? false;
        if (callId == null || fromUid == null || convId == null) return;
        // Хэт хуучин дуудлага бол үл тоомсорлоно (>40 сек)
        final ts = row['created_at'] as String?;
        if (ts != null) {
          final dt = DateTime.tryParse(ts);
          if (dt != null && DateTime.now().toUtc().difference(dt.toUtc()).inSeconds > 40) return;
          _lastSeenAt = ts;
        }
        debugPrint('[IncomingCallListener] poll picked $callId');
        if (!mounted) return;
        _showIncoming(
          callId: callId, fromUid: fromUid, fromName: fromName,
          convId: convId, isVideo: isVideo,
        );
      } catch (e) {
        debugPrint('[IncomingCallListener] poll алдаа: $e');
      }
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _pollTimer?.cancel();
    _ch?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ─────────────────────────────────────────────────────────────
// REC PULSE DOT — recording үед цохилох улаан цэг
// ─────────────────────────────────────────────────────────────
class _RecPulseDot extends StatefulWidget {
  @override
  State<_RecPulseDot> createState() => _RecPulseDotState();
}

class _RecPulseDotState extends State<_RecPulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => Container(
      width: 11, height: 11,
      decoration: BoxDecoration(
        color: Color.lerp(const Color(0xFFE8547A), const Color(0xFFFF8FA8), _ctrl.value),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(
          color: const Color(0xFFE8547A).withOpacity(0.4 + 0.4 * _ctrl.value),
          blurRadius: 6 + 4 * _ctrl.value,
        )],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// RECORDING WAVEFORM — анимэйшнтэй дуу бичих indicator
// ─────────────────────────────────────────────────────────────
class _RecordingWaveform extends StatefulWidget {
  final Color color;
  const _RecordingWaveform({required this.color});
  @override
  State<_RecordingWaveform> createState() => _RecordingWaveformState();
}

class _RecordingWaveformState extends State<_RecordingWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  // Тогтмол seed-ээр генерацлав — кадр болгонд дахин үүсгэхгүй
  static const _bars = 28;
  late final List<double> _phase;
  late final List<double> _amp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat();
    final rng = math.Random(7);
    _phase = List.generate(_bars, (_) => rng.nextDouble() * math.pi * 2);
    _amp   = List.generate(_bars, (_) => 0.4 + rng.nextDouble() * 0.6);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => SizedBox(
        height: 28,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(_bars, (i) {
            final t = _ctrl.value * math.pi * 2;
            final v = (math.sin(t + _phase[i]) * 0.5 + 0.5) * _amp[i];
            final h = 4 + v * 22;
            return Container(
              width: 3, height: h,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.6 + v * 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AUDIO MESSAGE BUBBLE — voice мессеж тоглуулах
// ─────────────────────────────────────────────────────────────
class _AudioMessageBubble extends StatefulWidget {
  final String? mediaUrl;
  final bool isMe;
  final ThemeColors c;
  final String fallbackLabel;
  const _AudioMessageBubble({
    required this.mediaUrl,
    required this.isMe,
    required this.c,
    required this.fallbackLabel,
  });
  @override
  State<_AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<_AudioMessageBubble> {
  final _player = AudioPlayer();
  bool _playing = false;
  bool _loading = false;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _playing = s == PlayerState.playing);
    });
    _player.onPositionChanged.listen((p) { if (mounted) setState(() => _pos = p); });
    _player.onDurationChanged.listen((d) { if (mounted) setState(() => _dur = d); });
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() { _playing = false; _pos = Duration.zero; });
    });
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  Future<void> _toggle() async {
    final src = widget.mediaUrl;
    if (src == null || src.isEmpty) return;
    if (_playing) {
      await _player.pause();
      return;
    }
    setState(() => _loading = true);
    try {
      // Local file path эсвэл URL гэдгийг ялгана
      final source = (src.startsWith('http://') || src.startsWith('https://'))
          ? UrlSource(src)
          : DeviceFileSource(src);
      await _player.play(source);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Дуу тоглуулахад алдаа гарлаа')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.isMe ? Colors.white : widget.c.primary;
    final track = fg.withOpacity(0.25);
    final progress = _dur.inMilliseconds > 0
        ? (_pos.inMilliseconds / _dur.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final timeLabel = _dur > Duration.zero
        ? '${_fmt(_pos)} / ${_fmt(_dur)}'
        : widget.fallbackLabel;

    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: fg.withOpacity(0.18), shape: BoxShape.circle),
          child: _loading
              ? Padding(
                  padding: const EdgeInsets.all(9),
                  child: CircularProgressIndicator(color: fg, strokeWidth: 2),
                )
              : Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: fg, size: 22),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 130,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress, minHeight: 3,
                backgroundColor: track,
                valueColor: AlwaysStoppedAnimation<Color>(fg),
              ),
            ),
            const SizedBox(height: 6),
            Text(timeLabel,
              style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}