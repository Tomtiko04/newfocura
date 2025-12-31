import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../providers/yearly_goals_provider.dart';
import '../../services/api_service.dart';

class YearlyGoalsScreen extends ConsumerStatefulWidget {
  const YearlyGoalsScreen({super.key});

  @override
  ConsumerState<YearlyGoalsScreen> createState() => _YearlyGoalsScreenState();
}

class _YearlyGoalsScreenState extends ConsumerState<YearlyGoalsScreen> {
  final _titleController = TextEditingController();
  final _whyController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isImporting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _whyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(yearlyGoalsProvider);
    final notifier = ref.read(yearlyGoalsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yearly Goals'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: notifier.loadGoals,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add Yearly Goal', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'e.g., Ship Focura v1',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _whyController,
                        decoration: const InputDecoration(
                          labelText: 'Why it matters',
                          hintText: 'Why is this important to you?',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now(),
                                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setState(() => _startDate = picked);
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _startDate == null
                                    ? 'Start (default Jan 1)'
                                    : 'Start: ${_startDate!.toLocal().toString().split(' ')[0]}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate ?? DateTime.now().add(const Duration(days: 180)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 366)),
                                );
                                if (picked != null) {
                                  setState(() => _endDate = picked);
                                }
                              },
                              icon: const Icon(Icons.event),
                              label: Text(
                                _endDate == null
                                    ? 'End (default Dec 31)'
                                    : 'End: ${_endDate!.toLocal().toString().split(' ')[0]}',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              if (_titleController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Title is required')),
                                );
                                return;
                              }
                              final ok = await notifier.addGoal(
                                title: _titleController.text.trim(),
                                why: _whyController.text.trim().isEmpty ? null : _whyController.text.trim(),
                                startDate: _startDate,
                                endDate: _endDate,
                              );
                              if (ok && mounted) {
                                _titleController.clear();
                                _whyController.clear();
                                _startDate = null;
                                _endDate = null;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Goal added')),
                                );
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Failed to add goal')),
                                );
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Goal'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _isImporting ? null : () => _showImportOptions(),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: Text(_isImporting ? 'Importing...' : 'Import from Snap'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Yearly Goals', style: Theme.of(context).textTheme.titleMedium),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: state.goals.isEmpty
                            ? null
                            : () async {
                                try {
                                  final results = await notifier.analyzeAll();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          results.isEmpty ? 'Analysis failed' : 'Analysis complete',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Analysis failed: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: const Icon(Icons.analytics),
                        label: const Text('Analyze all'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: state.analysisResults.isEmpty
                            ? null
                            : () async {
                                await notifier.finalizeAllWithAnalysis(state.analysisResults);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Yearly goals finalized')),
                                  );
                                }
                              },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Finalize'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (state.isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ))
              else if (state.goals.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No yearly goals yet. Add or import to get started.'),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.goals.length,
                  itemBuilder: (context, index) {
                    final goal = state.goals[index];
                    final analysis = state.analysisResults.firstWhere(
                      (a) => a.title == goal.title,
                      orElse: () => GoalAnalysis(title: goal.title),
                    );
                    return Card(
                      child: ListTile(
                        title: Text(goal.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (goal.why != null && goal.why!.isNotEmpty)
                              Text('Why: ${goal.why!}'),
                            Text(
                              'Start: ${goal.startDate?.toLocal().toString().split(' ')[0] ?? 'Jan 1'}'
                              '  •  End: ${goal.endDate?.toLocal().toString().split(' ')[0] ?? 'Dec 31'}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            if (analysis.feasibilityScore != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            value: (analysis.feasibilityScore ?? 0) / 100,
                                            backgroundColor: Colors.grey[200],
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              _getScoreColor(analysis.feasibilityScore ?? 0),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${analysis.feasibilityScore?.toStringAsFixed(0) ?? '--'}%',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _getScoreColor(analysis.feasibilityScore ?? 0),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (analysis.estimatedHours != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Estimated Time: ${analysis.estimatedHours!.toStringAsFixed(0)} hours',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            if (analysis.feasibilityComment != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    analysis.feasibilityComment!,
                                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                                  ),
                                ),
                              ),
                            if (analysis.strategicPivot != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Pivot: ${analysis.strategicPivot!}',
                                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                                ),
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'delete') {
                              await notifier.deleteGoal(goal.id);
                            } else if (value == 'edit') {
                              _showEditDialog(goal);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(YearlyGoal goal) {
    final titleController = TextEditingController(text: goal.title);
    final whyController = TextEditingController(text: goal.why);
    DateTime? startDate = goal.startDate;
    DateTime? endDate = goal.endDate;
    final notifier = ref.read(yearlyGoalsProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Goal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: whyController,
                decoration: const InputDecoration(labelText: 'Why it matters'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => startDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        startDate == null
                            ? 'Start (default Jan 1)'
                            : 'Start: ${startDate!.toLocal().toString().split(' ')[0]}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now().add(const Duration(days: 180)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 366)),
                        );
                        if (picked != null) {
                          setState(() => endDate = picked);
                        }
                      },
                      icon: const Icon(Icons.event),
                      label: Text(
                        endDate == null
                            ? 'End (default Dec 31)'
                            : 'End: ${endDate!.toLocal().toString().split(' ')[0]}',
                      ),
                    ),
                  ),
                ],
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
              await notifier.updateGoal(
                goal.id,
                title: titleController.text,
                why: whyController.text,
                startDate: startDate,
                endDate: endDate,
              );
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showImportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Select multiple from gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _importFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Capture photos'),
              onTap: () {
                Navigator.of(context).pop();
                _importFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importFromGallery() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    if (files.isEmpty) return;
    await _processImages(files);
  }

  Future<void> _importFromCamera() async {
    final picker = ImagePicker();
    final List<XFile> captures = [];
    while (true) {
      final file = await picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.rear);
      if (file == null) break;
      captures.add(file);
      // Stop if user cancels subsequent capture
      final continueCapture = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add another photo?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes')),
          ],
        ),
      );
      if (continueCapture != true) break;
    }
    if (captures.isEmpty) return;
    await _processImages(captures);
  }

  Future<void> _processImages(List<XFile> files) async {
    setState(() => _isImporting = true);
    try {
      final formData = FormData();
      for (final file in files) {
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(file.path, filename: file.name),
          ),
        );
      }

      final response = await apiService.post('/snap/goals', data: formData);
      final goals = (response.data['goals'] as List<dynamic>? ?? [])
          .map((g) => {
                'title': g['title'] as String?,
                'why': g['notes'] as String?, // map notes to why reflection
              })
          .toList();

      await ref.read(yearlyGoalsProvider.notifier).importGoals(goals);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${goals.length} goals')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to import goals')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.amber;
    return Colors.red;
  }
}

