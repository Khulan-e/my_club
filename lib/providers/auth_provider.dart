// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  User? _user;
  Map<String, dynamic>? _profile;
  bool _loading = true;

  User? get user => _user;
  Map<String, dynamic>? get profile => _profile;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;

  // ── Role helper-үүд ──────────────────────────────────────
  UserRole get userRole => UserRole.fromDb(_profile?['role']);

  bool get isStudent    => userRole == UserRole.student;
  bool get isClubAdmin  => userRole == UserRole.clubAdmin;
  bool get isSuperAdmin => userRole == UserRole.superAdmin;

  bool get isAdmin => isClubAdmin || isSuperAdmin;

  String? get managedClubId => _profile?['managed_club_id'];

  UserModel? get currentUser {
    if (_profile == null) return null;
    return UserModel.fromMap(_profile!);
  }

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _user = supabase.auth.currentUser;
    debugPrint('🔑 INIT START: user=${_user?.email}');
    if (_user != null) await _fetchProfile();
    _loading = false;
    debugPrint('🔑 INIT DONE: email=${_user?.email}, role=${_profile?['role']}, userRole=$userRole, isClubAdmin=$isClubAdmin');
    notifyListeners();

    _authService.authStateChanges.listen((event) async {
      _user = event.session?.user;
      debugPrint('🔄 AUTH STATE CHANGED: user=${_user?.email}');
      if (_user != null) {
        await _fetchProfile();
        debugPrint('🔄 AFTER FETCH: role=${_profile?['role']}, userRole=$userRole');
      } else {
        _profile = null;
        debugPrint('🔄 USER LOGGED OUT');
      }
      notifyListeners();
    });
  }

  Future<void> _fetchProfile() async {
    try {
      _profile = await _authService.getUser(_user!.id);
      debugPrint('✅ Profile loaded: id=${_user!.id}, role=${_profile?['role']}, managed_club=${_profile?['managed_club_id']}');
    } catch (e) {
      debugPrint('❌ Profile fetch error: $e');
      _profile = null;
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final res = await _authService.login(email, password);
      if (res.user == null) return 'Нэвтрэхэд алдаа гарлаа';

      _user = res.user;
      await _fetchProfile();
      debugPrint('🔐 LOGIN: email=$email, role=${_profile?['role']}, userRole=$userRole');
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid email or password')) {
        return 'И-мэйл эсвэл нууц үг буруу байна';
      }
      if (msg.contains('email not confirmed')) {
        return 'И-мэйл хаягаа баталгаажуулна уу';
      }
      if (msg.contains('too many requests')) {
        return 'Хэт олон оролдлого. Түр хүлээнэ үү';
      }
      return e.message;
    } catch (e) {
      return 'Алдаа гарлаа. Дахин оролдоно уу';
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String fullName,
    required String studentCode,
    required String school,
    required String department,
    required String phone,
  }) async {
    try {
      await _authService.register(
        email:       email,
        password:    password,
        fullName:    fullName,
        studentCode: studentCode,
        school:      school,
        department:  department,
        phone:       phone,
      );
      return null;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') ||
          msg.contains('already exists')) {
        return 'Энэ и-мэйл аль хэдийн бүртгэлтэй байна';
      }
      if (msg.contains('password')) {
        return 'Нууц үг хэт богино (дор хаяж 6 тэмдэгт)';
      }
      return e.message;
    } catch (e) {
      return 'Бүртгэл үүсгэхэд алдаа гарлаа';
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user    = null;
    _profile = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (_user != null) {
      await _fetchProfile();
      notifyListeners();
    }
  }
}