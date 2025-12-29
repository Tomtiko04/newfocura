import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/goals_provider.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No goals yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first goal to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(goalsProvider.notifier).loadGoals(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                return _GoalCard(
                  goal: goal,
                  onTap: () => _showGoalDetails(context, ref, goal),
                  onDelete: () => _deleteGoal(context, ref, goal.id),
                );
              },
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
              Text('Error loading goals: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(goalsProvider.notifier).loadGoals(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGoalDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }

  void _showCreateGoalDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDeadline;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g., Learn Mandarin',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (The Why)',
                    hintText: 'Why is this goal important?',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    selectedDeadline == null
                        ? 'Select Deadline *'
                        : 'Deadline: ${selectedDeadline!.toString().split(' ')[0]}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDeadline = date;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || selectedDeadline == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all required fields')),
                  );
                  return;
                }

                final success = await ref.read(goalsProvider.notifier).createGoal(
                      title: titleController.text,
                      description: descriptionController.text.isEmpty
                          ? null
                          : descriptionController.text,
                      deadline: selectedDeadline!,
                    );

                if (context.mounted) {
                  Navigator.of(context).pop();
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Goal created successfully')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to create goal')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalDetails(BuildContext context, WidgetRef ref, Goal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(goal.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (goal.description != null) ...[
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(goal.description!),
                const SizedBox(height: 16),
              ],
              Text(
                'Deadline',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(goal.deadline.toString().split(' ')[0]),
              const SizedBox(height: 16),
              if (goal.feasibilityScore != null) ...[
                Text(
                  'Feasibility Score',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: goal.feasibilityScore! / 100,
                  backgroundColor: Colors.grey[300],
                ),
                Text('${goal.feasibilityScore!.toStringAsFixed(1)}%'),
                const SizedBox(height: 16),
              ],
              if (goal.feasibilityAnalysis != null) ...[
                Text(
                  'Analysis',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(goal.feasibilityAnalysis!),
                const SizedBox(height: 16),
              ],
              if (goal.strategicPivot != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Strategic Pivot Suggestion',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(goal.strategicPivot!),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (goal.status != 'completed')
            ElevatedButton(
              onPressed: () async {
                final success = await ref.read(goalsProvider.notifier).updateGoal(
                      goal.id,
                      status: 'completed',
                    );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Goal marked as completed')),
                    );
                  }
                }
              },
              child: const Text('Mark Complete'),
            ),
        ],
      ),
    );
  }

  Future<void> _deleteGoal(BuildContext context, WidgetRef ref, String goalId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text('Are you sure you want to delete this goal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(goalsProvider.notifier).deleteGoal(goalId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Goal deleted' : 'Failed to delete goal'),
          ),
        );
      }
    }
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final daysUntilDeadline = goal.deadline.difference(DateTime.now()).inDays;
    final isOverdue = daysUntilDeadline < 0;
    final isDueSoon = daysUntilDeadline <= 7 && daysUntilDeadline >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: goal.status == 'completed'
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  if (goal.status == 'completed')
                    const Icon(Icons.check_circle, color: Colors.green),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    color: Colors.red,
                  ),
                ],
              ),
              if (goal.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  goal.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isOverdue
                        ? Colors.red
                        : isDueSoon
                            ? Colors.orange
                            : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOverdue
                        ? 'Overdue by ${-daysUntilDeadline} days'
                        : 'Due in $daysUntilDeadline days',
                    style: TextStyle(
                      color: isOverdue
                          ? Colors.red
                          : isDueSoon
                              ? Colors.orange
                              : Colors.grey[700],
                      fontWeight: isOverdue || isDueSoon ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
              if (goal.feasibilityScore != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Feasibility: '),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: goal.feasibilityScore! / 100,
                        backgroundColor: Colors.grey[300],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${goal.feasibilityScore!.toStringAsFixed(0)}%'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
