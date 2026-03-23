// lib/services/supabase_service.dart
// ignore_for_file: avoid_print
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
// Supabase client singleton
// ─────────────────────────────────────────────────────────────
final supabase = Supabase.instance.client;

// ─────────────────────────────────────────────────────────────
// AUTH SERVICE
// ─────────────────────────────────────────────────────────────
class AuthService {
  // Одоогийн хэрэглэгч
  User? get currentUser => supabase.auth.currentUser;
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  // ── Бүртгүүлэх ──────────────────────────────────────────
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
    required String studentCode,
    required String school,
    required String department,
    required String phone,
  }) async {
    final res = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    if (res.user != null) {
      // users хүснэгтийг шинэчлэх (trigger үүсгэсэн row-г update)
      await supabase.from('users').update({
        'full_name':    fullName,
        'student_code': studentCode,
        'school':       school,
        'department':   department,
        'phone':        phone,
      }).eq('id', res.user!.id);
    }
    return res;
  }

  // ── Нэвтрэх ─────────────────────────────────────────────
  Future<AuthResponse> login(String email, String password) =>
      supabase.auth.signInWithPassword(email: email, password: password);

  // ── Гарах ───────────────────────────────────────────────
  Future<void> logout() => supabase.auth.signOut();

  // ── Нууц үг сэргээх имэйл ───────────────────────────────
  Future<void> sendPasswordReset(String email) =>
      supabase.auth.resetPasswordForEmail(email);

  // ── Нууц үг солих (нэвтэрсэн үед) ──────────────────────
  Future<UserResponse> changePassword(String newPassword) =>
      supabase.auth.updateUser(UserAttributes(password: newPassword));

  // ── Профайл мэдээлэл засах ──────────────────────────────
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? school,
    String? department,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{};
    if (fullName   != null) data['full_name']   = fullName;
    if (phone      != null) data['phone']        = phone;
    if (school     != null) data['school']       = school;
    if (department != null) data['department']   = department;
    if (avatarUrl  != null) data['avatar_url']   = avatarUrl;
    if (data.isEmpty) return;

    await supabase.from('users').update(data).eq('id', userId);
  }

  // ── Хэрэглэгчийн мэдээлэл авах ─────────────────────────
  Future<Map<String, dynamic>?> getUser(String userId) async {
    final res = await supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return res;
  }
}

// ─────────────────────────────────────────────────────────────
// CLUB SERVICE
// ─────────────────────────────────────────────────────────────
class ClubService {
  // Бүх клубын жагсаалт
  Future<List<Map<String, dynamic>>> getClubs({String? category}) async {
    var query = supabase
        .from('clubs')
        .select()
        .eq('is_active', true);

    if (category != null) {
      query = query.eq('category', category);
    }

    return await query.order('name');
  }

  // Клубийн дэлгэрэнгүй
  Future<Map<String, dynamic>?> getClub(String clubId) async {
    return await supabase
        .from('clubs')
        .select()
        .eq('id', clubId)
        .maybeSingle();
  }

  // Хайлт
  Future<List<Map<String, dynamic>>> searchClubs(String query) async {
    return await supabase
        .from('clubs')
        .select()
        .eq('is_active', true)
        .or('name.ilike.%$query%,description.ilike.%$query%')
        .order('name');
  }

  // Клуб нэмэх (админ)
  Future<Map<String, dynamic>> createClub(Map<String, dynamic> data) async {
    final res = await supabase.from('clubs').insert(data).select().single();
    return res;
  }

  // Клуб засах (админ)
  Future<void> updateClub(String clubId, Map<String, dynamic> data) async {
    await supabase.from('clubs').update({...data, 'updated_at': DateTime.now().toIso8601String()}).eq('id', clubId);
  }

  // Клуб устгах (soft delete)
  Future<void> deleteClub(String clubId) async {
    await supabase.from('clubs').update({'is_active': false}).eq('id', clubId);
  }

  // Клубийн арга хэмжээнүүд
  Future<List<Map<String, dynamic>>> getClubEvents(String clubId) async {
    return await supabase
        .from('events')
        .select()
        .eq('club_id', clubId)
        .order('event_date', ascending: false);
  }

  // Клубийн сэтгэгдэлүүд
  Future<List<Map<String, dynamic>>> getClubReviews(String clubId) async {
    return await supabase
        .from('reviews')
        .select('*, users(full_name)')
        .eq('club_id', clubId)
        .eq('is_visible', true)
        .order('created_at', ascending: false);
  }
}

// ─────────────────────────────────────────────────────────────
// JOIN REQUEST SERVICE
// ─────────────────────────────────────────────────────────────
class JoinRequestService {
  // Элсэх хүсэлт илгээх
  Future<void> sendRequest({
    required String userId,
    required String clubId,
    required String clubName,
    required String message,
    required Map<String, dynamic> userData,
  }) async {
    // Давхардсан хүсэлт шалгах
    final existing = await supabase
        .from('join_requests')
        .select()
        .eq('user_id', userId)
        .eq('club_id', clubId)
        .eq('status', 'pending')
        .maybeSingle();

    if (existing != null) {
      throw Exception('Та аль хэдийн хүсэлт илгээсэн байна');
    }

    // Аль хэдийн гишүүн эсэх шалгах
    final member = await supabase
        .from('club_memberships')
        .select()
        .eq('user_id', userId)
        .eq('club_id', clubId)
        .maybeSingle();

    if (member != null) {
      throw Exception('Та энэ клубийн гишүүн байна');
    }

    await supabase.from('join_requests').insert({
      'user_id':          userId,
      'club_id':          clubId,
      'message':          message,
      'status':           'pending',
    });
  }

  // Хэрэглэгчийн хүсэлтүүд
  Future<List<Map<String, dynamic>>> getUserRequests(String userId) async {
    return await supabase
        .from('join_requests')
        .select('*, clubs(name, logo_url, category)')
        .eq('user_id', userId)
        .order('requested_at', ascending: false);
  }

  // Клубийн хүсэлтүүд (админ)
  Future<List<Map<String, dynamic>>> getClubRequests(String clubId) async {
    return await supabase
        .from('join_requests')
        .select('*, users(full_name, student_code, email, school, department)')
        .eq('club_id', clubId)
        .eq('status', 'pending')
        .order('requested_at');
  }

  // Бүх хүсэлтүүд (админ)
  Future<List<Map<String, dynamic>>> getAllPendingRequests() async {
    return await supabase
        .from('join_requests')
        .select('*, users(full_name, student_code, email), clubs(name)')
        .eq('status', 'pending')
        .order('requested_at');
  }

  // Хүсэлт батлах
  Future<void> approveRequest(String requestId) async {
    await supabase
        .from('join_requests')
        .update({'status': 'approved', 'reviewed_by': supabase.auth.currentUser!.id})
        .eq('id', requestId);
  }

  // Хүсэлт татгалзах
  Future<void> rejectRequest(String requestId) async {
    await supabase
        .from('join_requests')
        .update({'status': 'rejected', 'reviewed_by': supabase.auth.currentUser!.id})
        .eq('id', requestId);
  }
}

// ─────────────────────────────────────────────────────────────
// VOLUNTEER HOURS SERVICE
// ─────────────────────────────────────────────────────────────
class VolunteerHoursService {
  // Оюутны нийт цаг
  Future<List<Map<String, dynamic>>> getUserHours(String userId) async {
    return await supabase
        .from('volunteer_hours')
        .select('*, clubs(name)')
        .eq('user_id', userId)
        .order('added_at', ascending: false);
  }

  // Нийт хуримтлагдсан цаг
  Future<double> getTotalHours(String userId) async {
    final res = await supabase
        .from('volunteer_hours')
        .select('hours')
        .eq('user_id', userId);

    double total = 0;
    for (final row in res) {
      total += (row['hours'] as num).toDouble();
    }
    return total;
  }

  // Клубиар хуваасан цаг
  Future<List<Map<String, dynamic>>> getHoursByClub(String userId) async {
    return await supabase
        .from('student_hours_summary')
        .select()
        .eq('user_id', userId)
        .order('total_hours', ascending: false);
  }

  // Сайн дурын цаг нэмэх (нэг оюутан)
  Future<void> addHours({
    required String userId,
    required String clubId,
    required String eventId,
    required String eventTitle,
    required double hours,
  }) async {
    await supabase.from('volunteer_hours').insert({
      'user_id':     userId,
      'club_id':     clubId,
      'event_id':    eventId,
      'event_title': eventTitle,
      'hours':       hours,
      'added_by':    supabase.auth.currentUser!.id,
    });
  }

  // Бөөнөөр цаг нэмэх
  Future<void> addHoursBulk({
    required List<String> userIds,
    required String clubId,
    required String eventId,
    required String eventTitle,
    required double hours,
  }) async {
    final adminId = supabase.auth.currentUser!.id;
    final rows = userIds.map((uid) => {
      'user_id':     uid,
      'club_id':     clubId,
      'event_id':    eventId,
      'event_title': eventTitle,
      'hours':       hours,
      'added_by':    adminId,
    }).toList();

    await supabase.from('volunteer_hours').insert(rows);
  }
}

// ─────────────────────────────────────────────────────────────
// REVIEW SERVICE
// ─────────────────────────────────────────────────────────────
class ReviewService {
  // Сэтгэгдэл нэмэх / шинэчлэх
  Future<void> upsertReview({
    required String userId,
    required String clubId,
    required double rating,
    required String comment,
  }) async {
    await supabase.from('reviews').upsert({
      'user_id':  userId,
      'club_id':  clubId,
      'rating':   rating,
      'comment':  comment,
    }, onConflict: 'user_id,club_id');
  }

  // Хэрэглэгчийн сэтгэгдэлүүд
  Future<List<Map<String, dynamic>>> getUserReviews(String userId) async {
    return await supabase
        .from('reviews')
        .select('*, clubs(name, logo_url)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  // Сэтгэгдэл нуух (админ)
  Future<void> hideReview(String reviewId) async {
    await supabase.from('reviews').update({'is_visible': false}).eq('id', reviewId);
  }

  // Тухайн клубт хэрэглэгч үнэлгээ өгсөн эсэх
  Future<Map<String, dynamic>?> getMyReview(String userId, String clubId) async {
    return await supabase
        .from('reviews')
        .select()
        .eq('user_id', userId)
        .eq('club_id', clubId)
        .maybeSingle();
  }
}

// ─────────────────────────────────────────────────────────────
// EVENT SERVICE
// ─────────────────────────────────────────────────────────────
class EventService {
  // Арга хэмжээ үүсгэх
  Future<Map<String, dynamic>> createEvent({
    required String clubId,
    required String title,
    required String description,
    required String location,
    required DateTime eventDate,
    required double hours,
  }) async {
    final res = await supabase.from('events').insert({
      'club_id':     clubId,
      'title':       title,
      'description': description,
      'location':    location,
      'event_date':  eventDate.toIso8601String(),
      'hours':       hours,
      'created_by':  supabase.auth.currentUser!.id,
    }).select().single();
    return res;
  }

  // Ирэх арга хэмжээнүүд
  Future<List<Map<String, dynamic>>> getUpcomingEvents({String? clubId}) async {
    var query = supabase
        .from('events')
        .select('*, clubs(name)')
        .gte('event_date', DateTime.now().toIso8601String());

    if (clubId != null) query = query.eq('club_id', clubId);
    return await query.order('event_date');
  }

  // Клубийн арга хэмжээний оролцогчид
  Future<List<Map<String, dynamic>>> getEventParticipants(String eventId) async {
    return await supabase
        .from('volunteer_hours')
        .select('*, users(full_name, student_code)')
        .eq('event_id', eventId);
  }
}

// ─────────────────────────────────────────────────────────────
// ADMIN SERVICE
// ─────────────────────────────────────────────────────────────
class AdminService {
  // Dashboard статистик
  Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await supabase
        .from('admin_dashboard_stats')
        .select()
        .single();
    return res;
  }

  // Идэвхтэй клубүүд
  Future<List<Map<String, dynamic>>> getTopClubs() async {
    return await supabase
        .from('top_clubs')
        .select()
        .limit(10);
  }

  // Оюутанд admin role олгох
  Future<void> setUserRole(String userId, String role) async {
    await supabase.from('users').update({'role': role}).eq('id', userId);
  }

  // Бүх хэрэглэгчид (хайлттай)
  Future<List<Map<String, dynamic>>> getUsers({String? search}) async {
    var query = supabase
        .from('users')
        .select();

    if (search != null && search.isNotEmpty) {
      query = query.or('full_name.ilike.%$search%,student_code.ilike.%$search%,email.ilike.%$search%');
    }
    return await query.order('created_at', ascending: false);
  }

  // Клубийн гишүүдийн жагсаалт
  Future<List<Map<String, dynamic>>> getClubMembers(String clubId) async {
    return await supabase
        .from('club_memberships')
        .select('*, users(full_name, student_code, email, school, department)')
        .eq('club_id', clubId)
        .eq('status', 'approved')
        .order('joined_at');
  }

  // Гишүүнийг хасах
  Future<void> removeMember(String userId, String clubId) async {
    await supabase
        .from('club_memberships')
        .update({'status': 'removed'})
        .eq('user_id', userId)
        .eq('club_id', clubId);
  }
}