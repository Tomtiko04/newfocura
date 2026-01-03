import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final seenAppOnboarding = prefs.getBool('seen_onboarding') ?? false;

    // Allow auth state to hydrate
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final auth = ref.read(authStateProvider);
    
    if (!seenAppOnboarding) {
      // First time EVER opening the app on this device
      context.go('/onboarding');
      return;
    }

    if (!auth.isAuthenticated) {
      context.go('/login');
      return;
    }

    // User is authenticated, now check if they've done the "Reality Check" survey
    try {
      await ref.read(userProvider.notifier).loadReality();
      if (!mounted) return;
      
      final reality = ref.read(userProvider).value;

      if (reality == null || !reality.onboardingCompleted) {
        // Logged in but hasn't done the survey
        context.go('/reality-check');
      } else {
        // Fully onboarded
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      // Fallback to home if check fails
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5E35B1), Color(0xFFFF6F00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Focura',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your personal planning assistant',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

