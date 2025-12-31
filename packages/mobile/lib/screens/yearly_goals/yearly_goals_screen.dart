import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../providers/yearly_goals_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';

class YearlyGoalsScreen extends ConsumerStatefulWidget {
  const YearlyGoalsScreen({super.key});

  @override
  ConsumerState<YearlyGoalsScreen> createState() => _YearlyGoalsScreenState();
}

class _YearlyGoalsScreenState extends ConsumerState<YearlyGoalsScreen> with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _whyController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _skillLevel = 'beginner';
  bool _isImporting = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _whyController.dispose();
    _tabController.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Planning', icon: Icon(Icons.edit_note)),
            Tab(text: 'Roadmap', icon: Icon(Icons.map_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlanningTab(state, notifier),
          _buildRoadmapTab(state, notifier),
        ],
      ),
    );
  }

  Widget _buildPlanningTab(YearlyGoalsState state, YearlyGoalsNotifier notifier) {
    final userReality = ref.watch(userProvider).value;
    
    // Reality Alert Logic
    double totalHours = 0;
    for (final goal in state.goals) {
      final analysis = state.analysisResults.firstWhere(
        (a) => a.title == goal.title,
        orElse: () => GoalAnalysis(title: goal.title),
      );
      totalHours += (goal.estimatedHours ?? analysis.estimatedHours ?? 0);
    }

    // Rough capacity for the year (52 weeks)
    final weeklyCapacity = userReality != null 
      ? (userReality.weekdayFocusHours * 5) + userReality.weekendFocusHours
      : 40.0;
    final yearlyCapacity = weeklyCapacity * 50; // assuming 2 weeks vacation
    final isOverCapacity = totalHours > yearlyCapacity;

    return RefreshIndicator(
      onRefresh: notifier.loadGoals,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isOverCapacity && userReality != null)
              _buildRealityAlert(totalHours, yearlyCapacity),
            _buildAddGoalCard(notifier),
            const SizedBox(height: 16),
            _buildActionHeader(state, notifier),
            const SizedBox(height: 8),
            _buildGoalsList(state, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildRealityAlert(double total, double capacity) {
    final overage = total - capacity;
    final percent = (total / capacity * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
              const SizedBox(width: 8),
              Text(
                'Reality Alert: Resource Overload',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[900]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your goals require approx. ${total.toStringAsFixed(0)} hours this year, but your "Reality Check" profile says you only have ${capacity.toStringAsFixed(0)} hours available.',
            style: TextStyle(fontSize: 13, color: Colors.red[900]),
          ),
          const SizedBox(height: 4),
          Text(
            'You are at $percent% capacity. Burnout risk is EXTREMELY HIGH.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red[900]),
          ),
          const SizedBox(height: 12),
          Text(
            'Recommendation: Move low-impact goals to Bucket C or postpone to next year.',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.red[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildAddGoalCard(YearlyGoalsNotifier notifier) {
    return Card(
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
            const Text('Your foundation in this skill:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'beginner', label: Text('Zero')),
                ButtonSegment(value: 'intermediate', label: Text('Some')),
                ButtonSegment(value: 'expert', label: Text('Expert')),
              ],
              selected: {_skillLevel},
              onSelectionChanged: (set) => setState(() => _skillLevel = set.first),
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
                          ? 'Start'
                          : '${_startDate!.toLocal().toString().split(' ')[0]}',
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
                          ? 'End'
                          : '${_endDate!.toLocal().toString().split(' ')[0]}',
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
                      skillLevel: _skillLevel,
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
                  label: Text(_isImporting ? 'Importing...' : 'Snap'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionHeader(YearlyGoalsState state, YearlyGoalsNotifier notifier) {
    return Row(
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
    );
  }

  Widget _buildGoalsList(YearlyGoalsState state, YearlyGoalsNotifier notifier) {
    if (state.isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ));
    }
    if (state.goals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No yearly goals yet. Add or import to get started.'),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.goals.length,
      itemBuilder: (context, index) {
        final goal = state.goals[index];
        final analysis = state.analysisResults.firstWhere(
          (a) => a.title == goal.title,
          orElse: () => GoalAnalysis(title: goal.title),
        );
        return _buildGoalItem(goal, analysis, notifier);
      },
    );
  }

  Widget _buildGoalItem(YearlyGoal goal, GoalAnalysis analysis, YearlyGoalsNotifier notifier) {
    final bucket = goal.priorityBucket ?? analysis.priorityBucket;
    final quarter = goal.suggestedQuarter ?? analysis.suggestedQuarter;

    return Card(
      child: ListTile(
        title: Row(
          children: [
            Expanded(child: Text(goal.title)),
            if (bucket != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getBucketColor(bucket),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Bucket $bucket',
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (goal.why != null && goal.why!.isNotEmpty)
              Text('Why: ${goal.why!}'),
            Row(
              children: [
                Text(
                  'Start: ${goal.startDate?.toLocal().toString().split(' ')[0] ?? 'Jan 1'}'
                  '  •  End: ${goal.endDate?.toLocal().toString().split(' ')[0] ?? 'Dec 31'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (quarter != null) ...[
                  const Spacer(),
                  Text(
                    'Sequence: Q$quarter',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                ],
              ],
            ),
            if (analysis.feasibilityScore != null)
              _buildFeasibilityAnalysis(analysis),
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
  }

  Widget _buildFeasibilityAnalysis(GoalAnalysis analysis) {
    return Padding(
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
    );
  }

  Widget _buildRoadmapTab(YearlyGoalsState state, YearlyGoalsNotifier notifier) {
    if (state.goals.isEmpty) {
      return const Center(child: Text('No goals yet. Switch to Planning to add some.'));
    }

    // Group goals by suggested quarter
    final quarters = <int, List<YearlyGoal>>{
      1: [], 2: [], 3: [], 4: [],
    };
    
    for (final goal in state.goals) {
      final q = goal.suggestedQuarter ?? 1;
      quarters[q]?.add(goal);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Staggered Execution Plan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...[1, 2, 3, 4].map((q) {
            final goals = quarters[q]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.indigo,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'Q$q',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getQuarterLabel(q),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (goals.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(left: 52, bottom: 16),
                    child: Text('No goals scheduled for this quarter.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  )
                else
                  ...goals.map((g) => Padding(
                    padding: const EdgeInsets.only(left: 52, bottom: 8),
                    child: Card(
                      child: ListTile(
                        dense: true,
                        title: Text(g.title),
                        subtitle: g.priorityBucket != null 
                          ? Text('Bucket ${g.priorityBucket}', style: TextStyle(color: _getBucketColor(g.priorityBucket!)))
                          : null,
                      ),
                    ),
                  )),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _getQuarterLabel(int q) {
    switch (q) {
      case 1: return 'Foundations & Habits';
      case 2: return 'High-Energy Execution';
      case 3: return 'Aggressive Push';
      case 4: return 'Refinement & Launch';
      default: return '';
    }
  }

  Color _getBucketColor(String bucket) {
    switch (bucket) {
      case 'A': return Colors.red[400]!;
      case 'B': return Colors.orange[400]!;
      case 'C': return Colors.blue[400]!;
      default: return Colors.grey;
    }
  }

  void _showEditDialog(YearlyGoal goal) {
    final titleController = TextEditingController(text: goal.title);
    final whyController = TextEditingController(text: goal.why);
    DateTime? startDate = goal.startDate;
    DateTime? endDate = goal.endDate;
    String skillLevel = goal.skillLevel ?? 'beginner';
    String bucket = goal.priorityBucket ?? 'C';
    int quarter = goal.suggestedQuarter ?? 1;
    final notifier = ref.read(yearlyGoalsProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 16),
                const Text('Skill Level:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'beginner', label: Text('Zero')),
                    ButtonSegment(value: 'intermediate', label: Text('Some')),
                    ButtonSegment(value: 'expert', label: Text('Expert')),
                  ],
                  selected: {skillLevel},
                  onSelectionChanged: (set) => setDialogState(() => skillLevel = set.first),
                ),
                const SizedBox(height: 16),
                const Text('Priority Bucket:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'A', label: Text('A (Big 3)')),
                    ButtonSegment(value: 'B', label: Text('B')),
                    ButtonSegment(value: 'C', label: Text('C')),
                  ],
                  selected: {bucket},
                  onSelectionChanged: (set) => setDialogState(() => bucket = set.first),
                ),
                const SizedBox(height: 16),
                const Text('Scheduled Quarter:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('Q1')),
                    ButtonSegment(value: 2, label: Text('Q2')),
                    ButtonSegment(value: 3, label: Text('Q3')),
                    ButtonSegment(value: 4, label: Text('Q4')),
                  ],
                  selected: {quarter},
                  onSelectionChanged: (set) => setDialogState(() => quarter = set.first),
                ),
                const SizedBox(height: 16),
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
                            setDialogState(() => startDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          startDate == null
                              ? 'Start'
                              : '${startDate!.toLocal().toString().split(' ')[0]}',
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
                            setDialogState(() => endDate = picked);
                          }
                        },
                        icon: const Icon(Icons.event),
                        label: Text(
                          endDate == null
                              ? 'End'
                              : '${endDate!.toLocal().toString().split(' ')[0]}',
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
                  skillLevel: skillLevel,
                  priorityBucket: bucket,
                  suggestedQuarter: quarter,
                );
                if (mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
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

