// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  // supabase_flutter-д User гэдэг нь supabase_flutter-ийн User
  // import хийсний дараа автоматаар танигдана
  User? _user;
  Map<String, dynamic>? _profile;
  bool _loading = true;

  User? get user => _user;
  Map<String, dynamic>? get profile => _profile;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _profile?['role'] == 'admin';
  bool get isManager => _profile?['role'] == 'club_manager' || isAdmin;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _user = supabase.auth.currentUser;
    if (_user != null) await _fetchProfile();
    _loading = false;
    notifyListeners();

    _authService.authStateChanges.listen((event) async {
      _user = event.session?.user;
      if (_user != null) {
        await _fetchProfile();
      } else {
        _profile = null;
      }
      notifyListeners();
    });
  }

  Future<void> _fetchProfile() async {
    _profile = await _authService.getUser(_user!.id);
  }

  Future<String?> login(String email, String password) async {
    try {
      await _authService.login(email, password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Алдаа гарлаа. Дахин оролдоно уу.';
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
        email: email,
        password: password,
        fullName: fullName,
        studentCode: studentCode,
        school: school,
        department: department,
        phone: phone,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Бүртгэл үүсгэхэд алдаа гарлаа.';
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  Future<void> refreshProfile() async {
    if (_user != null) {
      await _fetchProfile();
      notifyListeners();
    }
  }
}