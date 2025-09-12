import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'login_page.dart';
import 'signup_page.dart';
import 'dashboard_page.dart';
import 'admin_page.dart';

void main() {
  runApp(AthrApp());
}

class AthrApp extends StatelessWidget {
  final GoRouter _router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LandingRedirect()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(path: '/admin', builder: (context, state) => const AdminPage()),
      // add more routes as needed
    ],
  );

  AthrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ATHR',
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF17efdf),
        scaffoldBackgroundColor: Colors.white,
      ),
    );
  }
}

class LandingRedirect extends StatelessWidget {
  const LandingRedirect({super.key});
  @override
  Widget build(BuildContext context) {
    // If someone hits /app/ root, redirect to login or dashboard depending on auth
    Future.microtask(() => context.go('/login'));
    return const SizedBox.shrink();
  }
}
