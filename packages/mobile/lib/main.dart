import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/snap/snap_screen.dart';
import 'screens/goals/goals_screen.dart';
import 'screens/tasks/tasks_screen.dart';
import 'screens/schedule/schedule_screen.dart';
import 'screens/morning_sync/morning_sync_screen.dart';
import 'screens/momentum/momentum_screen.dart';
import 'screens/yearly_goals/yearly_goals_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: FocuraApp(),
    ),
  );
}

class FocuraApp extends ConsumerWidget {
  const FocuraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state to trigger router rebuild when it changes
    ref.watch(authStateProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Focura',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  // Listen to auth state changes and refresh router
  ref.listen<AuthState>(authStateProvider, (previous, next) {
    if (previous?.isAuthenticated != next.isAuthenticated) {
      // Auth state changed, router will rebuild automatically via watch
    }
  });

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // Don't redirect if we're still loading
      if (authState.isLoading) {
        return null;
      }
      
      final isLoggedIn = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/snap',
        builder: (context, state) => const SnapScreen(),
      ),
      GoRoute(
        path: '/goals',
        builder: (context, state) => const GoalsScreen(),
      ),
      GoRoute(
        path: '/tasks',
        builder: (context, state) => const TasksScreen(),
      ),
      GoRoute(
        path: '/schedule',
        builder: (context, state) => const ScheduleScreen(),
      ),
      GoRoute(
        path: '/morning-sync',
        builder: (context, state) => const MorningSyncScreen(),
      ),
      GoRoute(
        path: '/momentum',
        builder: (context, state) => const MomentumScreen(),
      ),
      GoRoute(
        path: '/yearly-goals',
        builder: (context, state) => const YearlyGoalsScreen(),
      ),
    ],
  );
});

