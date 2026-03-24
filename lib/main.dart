// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'utils/theme_and_constants.dart';
import 'providers/auth_provider.dart';

// Auth
import 'screens/auth/auth_screens.dart';

// Student — тусдаа файл бүр
import 'screens/student/home_screen.dart';
import 'screens/student/club_detail_screen.dart';
import 'screens/student/my_profile_screen.dart';
import 'screens/student/my_clubs_screen.dart';
import 'screens/student/my_requests_screen.dart';
import 'screens/student/my_hours_screen.dart';
import 'screens/student/my_reviews_screen.dart';

// Admin
import 'screens/admin/admin_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:     'https://vmglqlkuuijfilpfnves.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZtZ2xxbGt1dWlqZmlscGZudmVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQyNTQ4NzcsImV4cCI6MjA4OTgzMDg3N30.Ngc0HfMq7075m-e_N8mKWdLhi2mTU2gT2zxbXBmsLrU',
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
      ],
      child: MaterialApp(
        title: 'ClubHub — ХУИС',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: '/login',
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
          // Admin
          '/admin':           (_) => const AdminDashboardScreen(),
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
      ),
    );
  }
}