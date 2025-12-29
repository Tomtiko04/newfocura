import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/goals_provider.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: tasksAsync.when(
        data: (allTasks) {
          final pendingTasks = allTasks.where((t) => t.status == 'pending').toList();
          final inProgressTasks = allTasks.where((t) => t.status == 'in_progress').toList();
          final completedTasks = allTasks.where((t) => t.status == 'completed').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTaskList(context, allTasks),
              _buildTaskList(context, pendingTasks),
              _buildTaskList(context, inProgressTasks),
              _buildTaskList(context, completedTasks),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading tasks: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(tasksProvider.notifier).loadTasks(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTaskDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checklist_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No tasks',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(tasksProvider.notifier).loadTasks(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return _TaskCard(
            task: task,
            onTap: () => _showTaskDetails(context, ref, task),
            onComplete: () => _completeTask(context, ref, task),
            onDelete: () => _deleteTask(context, ref, task.id),
          );
        },
      ),
    );
  }

  void _showCreateTaskDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final implementationIntentionController = TextEditingController();
    int priority = 3;
    String energyRequirement = 'Medium';
    String? selectedGoalId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final goalsAsync = ref.watch(goalsProvider);
          
          return AlertDialog(
            title: const Text('Create Task'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      hintText: 'e.g., Call Sam',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedGoalId,
                    decoration: const InputDecoration(
                      labelText: 'Related Goal (Optional)',
                    ),
                    items: goalsAsync.when(
                      data: (goals) => [
                        const DropdownMenuItem(value: null, child: Text('None')),
                        ...goals.map((g) => DropdownMenuItem(
                          value: g.id,
                          child: Text(g.title),
                        )),
                      ],
                      loading: () => [],
                      error: (_, __) => [],
                    ),
                    onChanged: (value) => setState(() => selectedGoalId = value),
                  ),
                  const SizedBox(height: 16),
                  Text('Priority: $priority'),
                  Slider(
                    value: priority.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: priority.toString(),
                    onChanged: (value) => setState(() => priority = value.toInt()),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: energyRequirement,
                    decoration: const InputDecoration(
                      labelText: 'Energy Requirement',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'High', child: Text('High')),
                      DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'Low', child: Text('Low')),
                    ],
                    onChanged: (value) => setState(() => energyRequirement = value!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: implementationIntentionController,
                    decoration: const InputDecoration(
                      labelText: 'Implementation Intention',
                      hintText: 'If [trigger], then [action]',
                    ),
                    maxLines: 2,
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
                  if (titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a title')),
                    );
                    return;
                  }

                  final success = await ref.read(tasksProvider.notifier).createTask(
                        title: titleController.text,
                        description: descriptionController.text.isEmpty
                            ? null
                            : descriptionController.text,
                        priority: priority,
                        energyRequirement: energyRequirement,
                        implementationIntention: implementationIntentionController.text.isEmpty
                            ? null
                            : implementationIntentionController.text,
                        goalId: selectedGoalId,
                      );

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task created successfully')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to create task')),
                      );
                    }
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTaskDetails(BuildContext context, WidgetRef ref, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (task.description != null) ...[
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(task.description!),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  _buildInfoChip('Priority', task.priority.toString()),
                  const SizedBox(width: 8),
                  _buildInfoChip('Energy', task.energyRequirement),
                ],
              ),
              const SizedBox(height: 16),
              if (task.implementationIntention.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Implementation Intention',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(task.implementationIntention),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (task.subtasks.isNotEmpty) ...[
                Text(
                  'Subtasks',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...task.subtasks.map((subtask) => CheckboxListTile(
                  title: Text(subtask.title),
                  subtitle: Text('${subtask.durationEstimate} mins'),
                  value: subtask.status == 'completed',
                  onChanged: subtask.status == 'completed'
                      ? null
                      : (value) => _completeSubtask(context, ref, task.id, subtask.id),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (task.status != 'completed')
            ElevatedButton(
              onPressed: () => _completeTask(context, ref, task),
              child: const Text('Mark Complete'),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      padding: EdgeInsets.zero,
    );
  }

  Future<void> _completeTask(BuildContext context, WidgetRef ref, Task task) async {
    final success = await ref.read(tasksProvider.notifier).updateTask(
          task.id,
          status: 'completed',
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Task completed' : 'Failed to complete task'),
        ),
      );
    }
  }

  Future<void> _completeSubtask(BuildContext context, WidgetRef ref, String taskId, String subtaskId) async {
    final success = await ref.read(tasksProvider.notifier).completeSubtask(taskId, subtaskId);
    if (context.mounted) {
      if (success) {
        // Reload tasks to get updated data
        await ref.read(tasksProvider.notifier).loadTasks();
        Navigator.of(context).pop();
        // Reopen dialog with updated task
        if (context.mounted) {
          final tasksAsync = ref.read(tasksProvider);
          tasksAsync.whenData((tasks) {
            try {
              final updatedTask = tasks.firstWhere((t) => t.id == taskId);
              if (context.mounted) {
                _showTaskDetails(context, ref, updatedTask);
              }
            } catch (e) {
              // Task not found, just show snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Subtask completed')),
              );
            }
          });
        }
      }
    }
  }

  Future<void> _deleteTask(BuildContext context, WidgetRef ref, String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
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
      final success = await ref.read(tasksProvider.notifier).deleteTask(taskId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Task deleted' : 'Failed to delete task'),
          ),
        );
      }
    }
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.onTap,
    required this.onComplete,
    required this.onDelete,
  });

  Color _getPriorityColor(int priority) {
    if (priority >= 4) return Colors.red;
    if (priority >= 3) return Colors.orange;
    return Colors.green;
  }

  Color _getEnergyColor(String energy) {
    switch (energy) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedSubtasks = task.subtasks.where((s) => s.status == 'completed').length;
    final totalSubtasks = task.subtasks.length;

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
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: task.status == 'completed'
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  if (task.status == 'completed')
                    const Icon(Icons.check_circle, color: Colors.green),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    color: Colors.red,
                    iconSize: 20,
                  ),
                ],
              ),
              if (task.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Priority ${task.priority}',
                      style: TextStyle(
                        color: _getPriorityColor(task.priority),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getEnergyColor(task.energyRequirement).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task.energyRequirement,
                      style: TextStyle(
                        color: _getEnergyColor(task.energyRequirement),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (task.status != 'completed') ...[
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Complete'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ],
              ),
              if (totalSubtasks > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.list, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$completedSubtasks/$totalSubtasks subtasks completed',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: completedSubtasks / totalSubtasks,
                        backgroundColor: Colors.grey[300],
                      ),
                    ),
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
