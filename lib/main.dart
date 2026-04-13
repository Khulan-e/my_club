// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'utils/theme_and_constants.dart';
import 'providers/auth_provider.dart';
import 'models/models.dart';
import 'providers/theme_provider.dart';

// Auth
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/change_password_screen.dart';

// Student
import 'screens/student/home_screen.dart';
import 'screens/student/club_detail_screen.dart';
import 'screens/student/my_profile_screen.dart';
import 'screens/student/my_clubs_screen.dart';
import 'screens/student/my_requests_screen.dart';
import 'screens/student/my_hours_screen.dart';
import 'screens/student/my_reviews_screen.dart';

// Admin (club_admin)
import 'screens/admin/admin_dashboard_screen.dart';

// Super Admin
import 'screens/super_admin/super_admin_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vmglqlkuuijfilpfnves.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZtZ2xxbGt1dWlqZmlscGZudmVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQyNTQ4NzcsImV4cCI6MjA4OTgzMDg3N30.Ngc0HfMq7075m-e_N8mKWdLhi2mTU2gT2zxbXBmsLrU',
  );

  runApp(const ClubHubApp());
}

class ClubHubApp extends StatelessWidget {
  const ClubHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'ClubHub — ХУИС',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            darkTheme: themeProvider.themeData,
            themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
            home: const AuthWrapper(),
            routes: {
              // Auth
              '/login':           (_) => const LoginScreen(),
              '/register':        (_) => const RegisterScreen(),
              '/forgot-password': (_) => const ForgotPasswordScreen(),
              '/change-password': (_) => const ChangePasswordScreen(),
              // Student
              '/home':            (_) => const HomeScreen(),
              '/profile':         (_) => const MyProfileScreen(),
              '/my-clubs':        (_) => const MyClubsScreen(),
              '/my-requests':     (_) => const MyRequestsScreen(),
              '/my-hours':        (_) => const MyHoursScreen(),
              '/my-reviews':      (_) => const MyReviewsScreen(),
              // Admin (club_admin)
              '/admin':           (_) => const AdminDashboardScreen(),
              // Super admin
              '/super-admin':     (_) => const SuperAdminScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/club-detail') {
                final clubId = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (_) => ClubDetailScreen(clubId: clubId),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!auth.isLoggedIn) {
          return const LoginScreen();
        }

        switch (auth.userRole) {
          case UserRole.superAdmin:
            return const SuperAdminScreen();
          case UserRole.clubAdmin:
            return const AdminDashboardScreen();
          case UserRole.student:
            return const HomeScreen();
        }
      },
    );
  }
}