import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      title: 'ATHR App',
      routerConfig: _router,
      theme: ThemeData(
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

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.go('/dashboard'),
          child: const Text('Login (demo)'),
        ),
      ),
    );
  }
}

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Signup')));
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ATHR Dashboard')),
    body: const Center(child: Text('Dashboard (placeholder)')),
  );
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin')),
    body: const Center(child: Text('Admin')),
  );
}
