import 'package:athr/firebase_options.dart';
import 'package:athr/app/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:athr/core/locator.dart';
import 'package:athr/core/services/firebase_service.dart';
import 'package:athr/core/services/incident_service.dart';
import 'features/auth/login_page.dart';
import 'features/auth/gatekeeper_page.dart';
import 'features/auth/signup_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/admin/admin_page.dart';
import 'features/dashboard/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider(
      '6LdynMorAAAAAPo2PAi3G5s3IHz2Iqpw2R2TnzdJ',
    ),
  );
  setupLocator();
  // Registering IncidentService
  locator.registerLazySingleton(() => IncidentService());
  runApp(AthrApp());
}

class AthrApp extends StatelessWidget {
  const AthrApp({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = locator<FirebaseService>();

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Athr',
      routerConfig: GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/', redirect: (_, __) => '/login'),
          GoRoute(
            path: '/login',
            builder: (context, state) =>
                const GatekeeperPage(child: LoginPage()),
          ),
          GoRoute(
            path: '/signup',
            builder: (context, state) =>
                const GatekeeperPage(child: SignupPage()),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
            routes: [
              GoRoute(
                path: 'settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
          GoRoute(path: '/admin', builder: (context, state) => AdminPage()),
        ],
        redirect: (BuildContext context, GoRouterState state) {
          final bool loggedIn = firebaseService.currentUser != null;
          final bool onLoginPage = state.matchedLocation == '/login';
          final bool onSignupPage = state.matchedLocation == '/signup';

          // If not logged in and not on an auth route, redirect to login
          if (!loggedIn && !onLoginPage && !onSignupPage) {
            return '/login';
          }

          // If logged in and on the login page, redirect to dashboard.
          if (loggedIn && onLoginPage) {
            return '/dashboard';
          }

          // No redirect needed
          return null;
        },
        refreshListenable: GoRouterRefreshStream(
          firebaseService.authStateChanges,
        ),
      ),
      theme: AppTheme.darkTheme,
    );
  }
}

/// A stream-based [ChangeNotifier] for [GoRouter].
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    stream.asBroadcastStream().listen((_) => notifyListeners());
  }
}
