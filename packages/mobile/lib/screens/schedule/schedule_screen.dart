import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Schedule'),
        actions: [
          // PFC Shield "Restructure Today" button
          TextButton.icon(
            onPressed: () {
              // TODO: Implement PFC Shield restructure
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PFC Shield restructure coming soon')),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Restructure'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Morning Peak section
          Container(
            color: AppTheme.getAdaptiveBackground('morning_peak'),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Morning Peak',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text('Tasks scheduled for peak energy'),
              ],
            ),
          ),
          // Afternoon Admin section
          Container(
            color: AppTheme.getAdaptiveBackground('afternoon_admin'),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Afternoon Admin',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text('Administrative tasks'),
              ],
            ),
          ),
          // Evening Reflection section
          Container(
            color: AppTheme.getAdaptiveBackground('evening_reflection'),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evening Reflection',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text('Reflection and planning'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

