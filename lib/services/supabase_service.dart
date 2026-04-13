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
  User? get currentUser => supabase.auth.currentUser;
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

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
      await supabase.from('users').update({
        'full_name':    fullName,
        'student_code': studentCode,
        'school':       school,
        'department':   department,
        'phone':        phone,
        'role':         'student',
      }).eq('id', res.user!.id);
    }
    return res;
  }

  Future<AuthResponse> login(String email, String password) =>
      supabase.auth.signInWithPassword(email: email, password: password);

  Future<void> logout() => supabase.auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      supabase.auth.resetPasswordForEmail(email);

  Future<UserResponse> changePassword(String newPassword) =>
      supabase.auth.updateUser(UserAttributes(password: newPassword));

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

  Future<Map<String, dynamic>?> getClub(String clubId) async {
    return await supabase
        .from('clubs')
        .select()
        .eq('id', clubId)
        .maybeSingle();
  }

  Future<List<Map<String, dynamic>>> searchClubs(String query) async {
    return await supabase
        .from('clubs')
        .select()
        .eq('is_active', true)
        .or('name.ilike.%$query%,description.ilike.%$query%')
        .order('name');
  }

  Future<Map<String, dynamic>> createClub(Map<String, dynamic> data) async {
    final res = await supabase.from('clubs').insert(data).select().single();
    return res;
  }

  Future<void> updateClub(String clubId, Map<String, dynamic> data) async {
    await supabase.from('clubs').update({...data, 'updated_at': DateTime.now().toIso8601String()}).eq('id', clubId);
  }

  Future<void> deleteClub(String clubId) async {
    await supabase.from('clubs').update({'is_active': false}).eq('id', clubId);
  }

  Future<List<Map<String, dynamic>>> getClubEvents(String clubId) async {
    return await supabase
        .from('events')
        .select()
        .eq('club_id', clubId)
        .order('event_date', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getClubReviews(String clubId) async {
    return await supabase
        .from('reviews')
        .select('*, users!reviews_user_id_fkey(full_name)')
        .eq('club_id', clubId)
        .eq('is_visible', true)
        .order('created_at', ascending: false);
  }
}

// ─────────────────────────────────────────────────────────────
// JOIN REQUEST SERVICE
// ─────────────────────────────────────────────────────────────
class JoinRequestService {
  Future<void> sendRequest({
    required String userId,
    required String clubId,
    required String clubName,
    required String message,
    required Map<String, dynamic> userData,
  }) async {
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
      'user_id': userId,
      'club_id': clubId,
      'message': message,
      'status':  'pending',
    });
  }

  Future<List<Map<String, dynamic>>> getUserRequests(String userId) async {
    return await supabase
        .from('join_requests')
        .select('*, clubs(name, logo_url, category)')
        .eq('user_id', userId)
        .order('requested_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getClubRequests(String clubId) async {
    return await supabase
        .from('join_requests')
        .select('*, users!join_requests_user_id_fkey(full_name, student_code, email, school, department)')
        .eq('club_id', clubId)
        .eq('status', 'pending')
        .order('requested_at');
  }

  Future<List<Map<String, dynamic>>> getAllPendingRequests() async {
    return await supabase
        .from('join_requests')
        .select('*, users!join_requests_user_id_fkey(full_name, student_code, email), clubs(name)')
        .eq('status', 'pending')
        .order('requested_at');
  }

  Future<void> approveRequest(String requestId) async {
    await supabase
        .from('join_requests')
        .update({'status': 'approved', 'reviewed_by': supabase.auth.currentUser!.id})
        .eq('id', requestId);
  }

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
  Future<List<Map<String, dynamic>>> getUserHours(String userId) async {
    return await supabase
        .from('volunteer_hours')
        .select('*, clubs(name)')
        .eq('user_id', userId)
        .order('added_at', ascending: false);
  }

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

  Future<List<Map<String, dynamic>>> getHoursByClub(String userId) async {
    return await supabase
        .from('student_hours_summary')
        .select()
        .eq('user_id', userId)
        .order('total_hours', ascending: false);
  }

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

  // ── Нэг оюутан + нэг арга хэмжээ = нэг л бүртгэл ──────────
  Future<void> addHoursBulk({
    required List<String> userIds,
    required String clubId,
    required String eventId,
    required String eventTitle,
    required double hours,
  }) async {
    final adminId = supabase.auth.currentUser!.id;

    // Аль хэдийн бүртгэгдсэн оюутнуудыг шүүх
    final existing = await supabase
        .from('volunteer_hours')
        .select('user_id')
        .eq('club_id', clubId)
        .eq('event_id', eventId)
        .inFilter('user_id', userIds);

    final alreadyAdded = Set<String>.from(
        (existing as List).map((h) => h['user_id'] as String));

    final newUserIds = userIds.where((uid) => !alreadyAdded.contains(uid)).toList();
    if (newUserIds.isEmpty) return;

    final rows = newUserIds.map((uid) => {
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
  Future<void> upsertReview({
    required String userId,
    required String clubId,
    required double rating,
    required String comment,
  }) async {
    await supabase.from('reviews').upsert({
      'user_id': userId,
      'club_id': clubId,
      'rating':  rating,
      'comment': comment,
    }, onConflict: 'user_id,club_id');
  }

  Future<List<Map<String, dynamic>>> getUserReviews(String userId) async {
    return await supabase
        .from('reviews')
        .select('*, clubs(name, logo_url)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<void> hideReview(String reviewId) async {
    await supabase.from('reviews').update({'is_visible': false}).eq('id', reviewId);
  }

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

  Future<List<Map<String, dynamic>>> getUpcomingEvents({String? clubId}) async {
    var query = supabase
        .from('events')
        .select('*, clubs(name)')
        .gte('event_date', DateTime.now().toIso8601String());

    if (clubId != null) query = query.eq('club_id', clubId);
    return await query.order('event_date');
  }

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
  Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await supabase
        .from('admin_dashboard_stats')
        .select()
        .single();
    return res;
  }

  Future<List<Map<String, dynamic>>> getTopClubs() async {
    return await supabase
        .from('top_clubs')
        .select()
        .limit(10);
  }

  Future<void> setUserRole(String userId, String role, {String? managedClubId}) async {
    final updates = <String, dynamic>{'role': role};

    if (role == 'club_admin' && managedClubId != null) {
      updates['managed_club_id'] = managedClubId;
    } else if (role == 'student') {
      updates['managed_club_id'] = null;
    }

    await supabase.from('users').update(updates).eq('id', userId);
  }

  Future<void> assignClubAdmin(String userId, String clubId) async {
    await supabase.from('users').update({
      'role': 'club_admin',
      'managed_club_id': clubId,
    }).eq('id', userId);
  }

  Future<void> revokeClubAdmin(String userId) async {
    await supabase.from('users').update({
      'role': 'student',
      'managed_club_id': null,
    }).eq('id', userId);
  }

  Future<List<Map<String, dynamic>>> getUsers({String? search}) async {
    var query = supabase.from('users').select();

    if (search != null && search.isNotEmpty) {
      query = query.or('full_name.ilike.%$search%,student_code.ilike.%$search%,email.ilike.%$search%');
    }
    return await query.order('created_at', ascending: false);
  }

  // ── Foreign key alias-тай — student_code, department харагдана ─
  Future<List<Map<String, dynamic>>> getClubMembers(String clubId) async {
    return await supabase
        .from('club_memberships')
        .select('user_id, joined_at, users!club_memberships_user_id_fkey(full_name, student_code, email, school, department, avatar_url, role)')
        .eq('club_id', clubId)
        .eq('status', 'approved')
        .order('joined_at');
  }

  Future<void> removeMember(String userId, String clubId) async {
    await supabase
        .from('club_memberships')
        .update({'status': 'removed'})
        .eq('user_id', userId)
        .eq('club_id', clubId);
  }
}