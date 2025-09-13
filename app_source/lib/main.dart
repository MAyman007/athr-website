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
      debugShowCheckedModeBanner: false,
      title: 'Athr',
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF04192a),
        primaryColor: const Color(0xFF17efdf),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF17efdf),
          secondary: Color(0xFF17efdf),
          background: Color(0xFF04192a),
          surface: Color(0xFF0d263a),
          onPrimary: Color(0xFF04192a),
          onSecondary: Color(0xFF04192a),
          onBackground: Color(0xFFe9ecef),
          onSurface: Color(0xFFe9ecef),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0d263a),
          foregroundColor: Color(0xFFe9ecef),
        ),
        cardTheme: const CardThemeData(color: Color(0xFF0d263a), elevation: 4),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFe9ecef)),
          bodyMedium: TextStyle(color: Color(0xFFa0b3c4)),
          headlineMedium: TextStyle(color: Color(0xFFe9ecef)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF17efdf),
            foregroundColor: const Color(0xFF04192a),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF17efdf)),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Color(0xFFa0b3c4)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFa0b3c4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF17efdf)),
          ),
        ),
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
