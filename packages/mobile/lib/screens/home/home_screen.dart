import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focura'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _FeatureCard(
            title: 'Snap',
            icon: Icons.camera_alt,
            color: Colors.blue,
            onTap: () => context.go('/snap'),
          ),
          _FeatureCard(
            title: 'Goals',
            icon: Icons.flag,
            color: Colors.green,
            onTap: () => context.go('/goals'),
          ),
          _FeatureCard(
            title: 'Tasks',
            icon: Icons.checklist,
            color: Colors.orange,
            onTap: () => context.go('/tasks'),
          ),
          _FeatureCard(
            title: 'Schedule',
            icon: Icons.calendar_today,
            color: Colors.purple,
            onTap: () => context.go('/schedule'),
          ),
          _FeatureCard(
            title: 'Morning Sync',
            icon: Icons.wb_sunny,
            color: Colors.amber,
            onTap: () => context.go('/morning-sync'),
          ),
          _FeatureCard(
            title: 'Momentum',
            icon: Icons.trending_up,
            color: Colors.red,
            onTap: () => context.go('/momentum'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/snap'),
        icon: const Icon(Icons.camera_alt),
        label: const Text('Snap'),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

