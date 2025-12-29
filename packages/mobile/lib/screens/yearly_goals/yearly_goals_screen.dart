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
  final _descriptionController = TextEditingController();
  final _whyController = TextEditingController();
  bool _isImporting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'What is the goal about?',
                        ),
                        maxLines: 2,
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
                                description: _descriptionController.text.trim().isEmpty
                                    ? null
                                    : _descriptionController.text.trim(),
                                why: _whyController.text.trim().isEmpty ? null : _whyController.text.trim(),
                              );
                              if (ok && mounted) {
                                _titleController.clear();
                                _descriptionController.clear();
                                _whyController.clear();
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
                            if (goal.description != null && goal.description!.isNotEmpty)
                              Text(goal.description!),
                            if (goal.why != null && goal.why!.isNotEmpty)
                              Text('Why: ${goal.why!}'),
                            if (analysis.feasibilityScore != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: (analysis.feasibilityScore ?? 0) / 100,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${analysis.feasibilityScore?.toStringAsFixed(0) ?? '--'}%'),
                                  ],
                                ),
                              ),
                            if (analysis.feasibilityComment != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  analysis.feasibilityComment!,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
    final descController = TextEditingController(text: goal.description);
    final whyController = TextEditingController(text: goal.why);
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
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              TextField(
                controller: whyController,
                decoration: const InputDecoration(labelText: 'Why it matters'),
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
              await notifier.updateGoal(
                goal.id,
                title: titleController.text,
                description: descController.text,
                why: whyController.text,
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
                'description': g['notes'] as String?,
                'why': null,
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
}

