import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/momentum_provider.dart';

class MomentumScreen extends ConsumerWidget {
  const MomentumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final momentumAsync = ref.watch(momentumProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('1% Better Momentum'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(momentumProvider.notifier).loadTodayMomentum(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: momentumAsync.when(
        data: (momentumData) {
          if (momentumData == null || momentumData.score == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No momentum data yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete tasks and submit morning sync to build momentum',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final score = momentumData.score!;
          final feedback = momentumData.feedback;

          return RefreshIndicator(
            onRefresh: () => ref.read(momentumProvider.notifier).loadTodayMomentum(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Overall Score Card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            'Today\'s Momentum Score',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: CircularProgressIndicator(
                                  value: score.overallScore / 100,
                                  strokeWidth: 20,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getScoreColor(score.overallScore),
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    score.overallScore.toStringAsFixed(0),
                                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _getScoreColor(score.overallScore),
                                    ),
                                  ),
                                  Text(
                                    '/100',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (feedback != null && feedback.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _getScoreColor(score.overallScore).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                feedback,
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Breakdown Cards
                  Text(
                    'Score Breakdown',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Consistency
                  _MetricCard(
                    title: 'Consistency',
                    value: score.consistency ? 100.0 : 0.0,
                    icon: Icons.check_circle_outline,
                    description: score.consistency
                        ? 'You completed at least one subtask today!'
                        : 'Complete at least one subtask to build consistency',
                    color: score.consistency ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  // Energy Alignment
                  _MetricCard(
                    title: 'Energy Alignment',
                    value: score.energyAlignment * 100,
                    icon: Icons.battery_charging_full,
                    description: 'How well your task completion aligns with your energy peaks',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  // Recovery
                  _MetricCard(
                    title: 'Recovery',
                    value: score.recovery * 100,
                    icon: Icons.bedtime,
                    description: 'Sleep and wake consistency',
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading momentum: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(momentumProvider.notifier).loadTodayMomentum(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.amber;
    return Colors.red;
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final String description;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${value.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
