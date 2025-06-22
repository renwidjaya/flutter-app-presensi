import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../widgets/bottom_nav.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/dashboard_screen.dart';
import '../../features/home/absensi_screen.dart';
import '../../features/home/riwayat_screen.dart';
import '../../features/home/statistik_screen.dart';
import '../../features/home/report_screen.dart';

class AppRouter {
  static final _storage = const FlutterSecureStorage();

  static final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final token = await _storage.read(key: 'token');
      final isLoggingIn = state.matchedLocation == '/';
      if (token != null && isLoggingIn) {
        return '/dashboard';
      } else if (token == null && !isLoggingIn) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LoginScreen()),

      /// ✅ ShellRoute untuk layout dengan BottomNav
      ShellRoute(
        builder: (context, state, child) {
          // Tentukan currentIndex dari path
          final location = state.uri.path;
          int index = 0;
          if (location == '/riwayat')
            index = 1;
          else if (location == '/statistik')
            index = 2;
          else if (location == '/report')
            index = 3;

          return Scaffold(
            body: child,
            bottomNavigationBar: BottomNav(currentIndex: index),
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/absensi',
            builder: (context, state) => const AbsensiScreen(),
          ),
          GoRoute(
            path: '/riwayat',
            builder: (context, state) => const RiwayatScreen(),
          ),
          GoRoute(
            path: '/statistik',
            builder: (context, state) => const StatistikScreen(),
          ),
          GoRoute(
            path: '/report',
            builder: (context, state) => const ReportScreen(),
          ),
        ],
      ),
    ],
  );
}
