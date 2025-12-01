import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/pages/dashboard_page.dart';
import '../presentation/pages/game_results_page.dart';
import '../presentation/pages/game_stats_page.dart';
import '../presentation/pages/login_page.dart';
import '../presentation/pages/reports_page.dart';
import '../presentation/pages/retention_page.dart';
import '../presentation/pages/users_analytics_page.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/widgets/admin_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(adminAuthProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState == AdminAuthState.authenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      // If not authenticated, redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // If authenticated and on login page, redirect to dashboard
      if (isLoggedIn && isLoggingIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersAnalyticsPage(),
          ),
          GoRoute(
            path: '/retention',
            builder: (context, state) => const RetentionPage(),
          ),
          GoRoute(
            path: '/games',
            builder: (context, state) => const GameStatsPage(),
          ),
          GoRoute(
            path: '/game-results',
            builder: (context, state) => const GameResultsPage(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsPage(),
          ),
        ],
      ),
    ],
  );
});
