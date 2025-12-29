import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../theme/app_theme.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(scheduleProvider);
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Schedule'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final success = await ref.read(scheduleProvider.notifier).generateSchedule();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Schedule generated successfully'
                        : 'Failed to generate schedule'),
                  ),
                );
              }
            },
            tooltip: 'Generate Schedule',
          ),
        ],
      ),
      body: scheduleAsync.when(
        data: (schedule) {
          if (schedule == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No schedule yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generate your daily schedule',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final success = await ref.read(scheduleProvider.notifier).generateSchedule();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Schedule generated successfully'
                                : 'Failed to generate schedule'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate Schedule'),
                  ),
                ],
              ),
            );
          }

          return tasksAsync.when(
            data: (allTasks) {
              final morningTasks = schedule.morningPeakTasks
                  .map((id) {
                    try {
                      return allTasks.firstWhere((t) => t.id == id);
                    } catch (e) {
                      return null;
                    }
                  })
                  .where((t) => t != null)
                  .cast<Task>()
                  .toList();
              final afternoonTasks = schedule.afternoonAdminTasks
                  .map((id) {
                    try {
                      return allTasks.firstWhere((t) => t.id == id);
                    } catch (e) {
                      return null;
                    }
                  })
                  .where((t) => t != null)
                  .cast<Task>()
                  .toList();
              final eveningTasks = schedule.eveningReflectionTasks
                  .map((id) {
                    try {
                      return allTasks.firstWhere((t) => t.id == id);
                    } catch (e) {
                      return null;
                    }
                  })
                  .where((t) => t != null)
                  .cast<Task>()
                  .toList();

              return RefreshIndicator(
                onRefresh: () => ref.read(scheduleProvider.notifier).loadTodaySchedule(),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Morning Peak section
                      Container(
                        width: double.infinity,
                        color: AppTheme.getAdaptiveBackground('morning_peak'),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.wb_sunny, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  'Morning Peak',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'High-energy tasks scheduled for your peak focus time',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (morningTasks.isEmpty)
                              Text(
                                'No tasks scheduled',
                                style: TextStyle(color: Colors.white.withOpacity(0.8)),
                              )
                            else
                              ...morningTasks.map((task) => _ScheduleTaskCard(
                                    task: task,
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    textColor: Colors.white,
                                  )),
                          ],
                        ),
                      ),
                      // Afternoon Admin section
                      Container(
                        width: double.infinity,
                        color: AppTheme.getAdaptiveBackground('afternoon_admin'),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.work_outline, color: Colors.brown[900]),
                                const SizedBox(width: 8),
                                Text(
                                  'Afternoon Admin',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.brown[900],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Administrative and low-energy tasks',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.brown[800],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (afternoonTasks.isEmpty)
                              Text(
                                'No tasks scheduled',
                                style: TextStyle(color: Colors.brown[700]),
                              )
                            else
                              ...afternoonTasks.map((task) => _ScheduleTaskCard(
                                    task: task,
                                    backgroundColor: Colors.white,
                                    textColor: Colors.brown[900]!,
                                  )),
                          ],
                        ),
                      ),
                      // Evening Reflection section
                      Container(
                        width: double.infinity,
                        color: AppTheme.getAdaptiveBackground('evening_reflection'),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.nightlight_round, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  'Evening Reflection',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Reflection and planning tasks',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (eveningTasks.isEmpty)
                              Text(
                                'No tasks scheduled',
                                style: TextStyle(color: Colors.white.withOpacity(0.8)),
                              )
                            else
                              ...eveningTasks.map((task) => _ScheduleTaskCard(
                                    task: task,
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    textColor: Colors.white,
                                  )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error loading tasks: $error'),
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
              Text('Error loading schedule: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(scheduleProvider.notifier).loadTodaySchedule(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleTaskCard extends StatelessWidget {
  final Task task;
  final Color backgroundColor;
  final Color textColor;

  const _ScheduleTaskCard({
    required this.task,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (task.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description!,
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (task.implementationIntention.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.implementationIntention,
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (task.priority != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'P${task.priority}',
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
