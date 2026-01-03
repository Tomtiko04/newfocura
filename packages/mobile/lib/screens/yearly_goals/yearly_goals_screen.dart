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
  int _planningStep = 0; // 0: Normal, 1: Baseline, 2: Pre-Mortem, 3: Yearly Contract
  
  // Controllers for the multi-step strategy design
  final Map<String, TextEditingController> _baselineControllers = {};
  final Map<String, TextEditingController> _riskControllers = {};
  final Map<String, TextEditingController> _recoveryControllers = {};

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
    for (var c in _baselineControllers.values) {
      c.dispose();
    }
    for (var c in _riskControllers.values) {
      c.dispose();
    }
    for (var c in _recoveryControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(yearlyGoalsProvider);
    final notifier = ref.read(yearlyGoalsProvider.notifier);

    if (_planningStep > 0) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('2026 Strategy Design'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _planningStep = 0),
          ),
        ),
        body: _buildPlanningWorkflow(state, notifier),
      );
    }

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
    final hasAnalysis = state.analysisResults.isNotEmpty;
    
    // Reality Budget Logic (Hybrid Math)
    double hoursA = 0;
    double hoursB = 0;
    double hoursC = 0;

    for (final goal in state.goals) {
      final analysis = state.analysisResults.firstWhere(
        (a) => a.title == goal.title,
        orElse: () => GoalAnalysis(title: goal.title),
      );
      
      final currentBucket = (state.analysisResults.any((a) => a.title == goal.title))
          ? analysis.priorityBucket
          : goal.priorityBucket;
      
      final hours = goal.estimatedHours ?? analysis.estimatedHours ?? 0;
      
      if (currentBucket == 'A') hoursA += hours;
      else if (currentBucket == 'B') hoursB += hours;
      else hoursC += hours;
    }

    final weeklyCapacity = userReality != null 
      ? (userReality.weekdayFocusHours * 5) + userReality.weekendFocusHours
      : 40.0;
    final yearlyCapacity = weeklyCapacity * 50;
    
    final capA = yearlyCapacity * 0.6;
    final capB = yearlyCapacity * 0.3;
    
    final isOverA = hoursA > capA;
    final isOverB = hoursB > capB;
    final isOverTotal = (hoursA + hoursB) > (capA + capB);

    return RefreshIndicator(
      onRefresh: notifier.loadGoals,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasAnalysis && userReality != null)
              _buildLiveBudgetView(hoursA, capA, hoursB, capB, hoursC, isOverTotal),
            if (hasAnalysis)
              _buildNextStepsCard(notifier, state, isOverTotal),
            _buildAddGoalCard(notifier),
            const SizedBox(height: 16),
            _buildActionHeader(state, notifier, isOverTotal),
            const SizedBox(height: 8),
            _buildGoalsList(state, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveBudgetView(double hA, double capA, double hB, double capB, double hC, bool isOver) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOver ? Colors.red[50] : Colors.green[50],
        border: Border.all(color: isOver ? Colors.red[200]! : Colors.green[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOver ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                color: isOver ? Colors.red[700] : Colors.green[700],
              ),
              const SizedBox(width: 8),
              Text(
                isOver ? 'Reality Alert: Resource Overload' : 'Capacity Check: Healthy',
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: isOver ? Colors.red[900] : Colors.green[900],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBudgetBar('🏆 Bucket A (Focus)', hA, capA, Colors.red[400]!),
          const SizedBox(height: 8),
          _buildBudgetBar('🥈 Bucket B (Support)', hB, capB, Colors.orange[400]!),
          const SizedBox(height: 8),
          _buildBudgetBar('🥉 Bucket C (Backlog)', hC, null, Colors.blue[400]!),
          if (isOver)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Recommendation: Move low-impact goals to Bucket C or a later Quarter to turn this green.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.red[700]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBudgetBar(String label, double used, double? cap, Color color) {
    final double percent = cap != null ? (used / cap).clamp(0.0, 1.0) : 0.0;
    final bool isFull = cap != null && used > cap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text(
              cap != null ? '${used.toStringAsFixed(0)} / ${cap.toStringAsFixed(0)} hrs' : '${used.toStringAsFixed(0)} hrs',
              style: TextStyle(fontSize: 11, color: isFull ? Colors.red : Colors.grey[700]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (cap != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(isFull ? Colors.red : color),
              minHeight: 6,
            ),
          )
        else
          const Text('Unlimited (Safe Zone)', style: TextStyle(fontSize: 10, color: Colors.blue)),
      ],
    );
  }

  Widget _buildNextStepsCard(YearlyGoalsNotifier notifier, YearlyGoalsState state, bool isOver) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                'Analysis Complete: Next Steps',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[900]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '1. Review the "Strategic Pivot" and "Challenges" for each goal below.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            '2. Check the "Roadmap" tab to see your new sequence (Q1-Q4).',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            '3. Click "Finalize" below to lock in this plan.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleFinalize(notifier, state, isOver),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.check_circle),
              label: const Text('Finalize Plan Now'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFinalize(YearlyGoalsNotifier notifier, YearlyGoalsState state, bool isOver) async {
    if (isOver) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Reality Check: Overload'),
            ],
          ),
          content: const Text(
            'You\'ve committed to a high-intensity year. Your current goals are significantly over-capacity. \n\nFocura will save this plan, but we recommend checking in weekly to avoid burnout. \n\nDo you want to proceed or fix your buckets?',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              child: const Text('Fix My Buckets'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Proceed Anyway', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (proceed != true) {
        _tabController.animateTo(1); // Switch to Roadmap to fix
        return;
      }
    }

    // LOCK IN THE PLAN FIRST: Save buckets and quarters to database
    await notifier.finalizeAllWithAnalysis(state.analysisResults);

    // Start multi-step workflow for the Big 3
    setState(() => _planningStep = 1);
  }

  Widget _buildPlanningWorkflow(YearlyGoalsState state, YearlyGoalsNotifier notifier) {
    if (_planningStep == 1) return _buildBaselineStep(state, notifier);
    if (_planningStep == 2) return _buildPreMortemStep(state, notifier);
    if (_planningStep == 3) return _buildYearlyContractView(state, notifier);
    return const SizedBox.shrink();
  }

  Widget _buildBaselineStep(YearlyGoalsState state, YearlyGoalsNotifier notifier) {
    // Filter Bucket A goals based on the LATEST analysis/triage state
    final bucketAGoals = state.goals.where((g) {
      final analysis = state.analysisResults.firstWhere(
        (a) => a.title == g.title, 
        orElse: () => GoalAnalysis(title: g.title),
      );
      // Use analysis result bucket if it exists (latest triage), otherwise goal bucket
      final currentBucket = (state.analysisResults.any((a) => a.title == g.title))
          ? analysis.priorityBucket
          : g.priorityBucket;
      return currentBucket == 'A';
    }).toList();

    if (bucketAGoals.isEmpty) {
      // If no Bucket A goals, skip to next step or contract
      Future.microtask(() => setState(() => _planningStep = 2));
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      key: const ValueKey('baseline_step_scroll'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Step 1: Day 1 Baseline', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('A goal without a starting point is just a wish. Tell Focura where you are starting today for your "Big 3" goals.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          ...bucketAGoals.map((goal) {
            final controller = _baselineControllers.putIfAbsent(
              goal.id, 
              () => TextEditingController(text: goal.baselineValue),
            );
            
            final analysis = state.analysisResults.firstWhere(
              (a) => a.title == goal.title, 
              orElse: () => GoalAnalysis(title: goal.title),
            );
            final prompt = goal.aiBaselinePrompt ?? analysis.aiBaselinePrompt ?? 'What is your current starting point for this goal?';
            
            return Card(
              key: ValueKey('baseline_card_${goal.id}'),
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                    const SizedBox(height: 12),
                    Text(prompt, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    TextField(
                      key: ValueKey('baseline_field_${goal.id}'),
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Starting Point',
                        hintText: prompt.toLowerCase().contains('weight') 
                          ? 'e.g. 85kg' 
                          : prompt.toLowerCase().contains('1-10') 
                            ? 'e.g. 3/10' 
                            : 'Describe your status today...',
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (val) => notifier.updateGoalPlanning(goal.id, baselineValue: val),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // Save all before moving
                for (var goal in bucketAGoals) {
                  final val = _baselineControllers[goal.id]?.text;
                  if (val != null) {
                    await notifier.updateGoalPlanning(goal.id, baselineValue: val);
                  }
                }
                setState(() => _planningStep = 2);
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Next: Planning for Obstacles'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreMortemStep(YearlyGoalsState state, YearlyGoalsNotifier notifier) {
    // Filter Bucket A goals based on the LATEST analysis/triage state
    final bucketAGoals = state.goals.where((g) {
      final analysis = state.analysisResults.firstWhere(
        (a) => a.title == g.title, 
        orElse: () => GoalAnalysis(title: g.title),
      );
      final currentBucket = (state.analysisResults.any((a) => a.title == g.title))
          ? analysis.priorityBucket
          : g.priorityBucket;
      return currentBucket == 'A';
    }).toList();

    if (bucketAGoals.isEmpty) {
      Future.microtask(() => setState(() => _planningStep = 3));
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      key: const ValueKey('pre_mortem_step_scroll'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Step 2: Pre-Mortem', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Imagine it is December 2026 and you failed. Why did it happen? Planning for obstacles now makes you 3x more likely to succeed.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          ...bucketAGoals.map((goal) {
            final riskController = _riskControllers.putIfAbsent(
              goal.id, 
              () => TextEditingController(text: goal.failureRisk),
            );
            final recoveryController = _recoveryControllers.putIfAbsent(
              goal.id, 
              () => TextEditingController(text: goal.recoveryStrategy),
            );

            return Card(
              key: ValueKey('pre_mortem_card_${goal.id}'),
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.redAccent)),
                    const SizedBox(height: 12),
                    const Text('What is the #1 risk that could stop you?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      key: ValueKey('risk_field_${goal.id}'),
                      controller: riskController,
                      decoration: InputDecoration(
                        labelText: 'Primary Risk',
                        hintText: goal.title.toLowerCase().contains('fitness') 
                          ? 'e.g. Injury or loss of motivation' 
                          : (goal.title.toLowerCase().contains('skill') || goal.title.toLowerCase().contains('learn'))
                            ? 'e.g. Getting stuck on a complex topic'
                            : 'What could go wrong?',
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (val) => notifier.updateGoalPlanning(goal.id, failureRisk: val),
                    ),
                    const SizedBox(height: 16),
                    const Text('If that happens, what is your "If-Then" recovery plan?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      key: ValueKey('recovery_field_${goal.id}'),
                      controller: recoveryController,
                      decoration: InputDecoration(
                        labelText: 'Recovery Plan',
                        hintText: goal.title.toLowerCase().contains('fitness') 
                          ? 'e.g. If I get injured, I will focus on mobility.' 
                          : 'e.g. If I get burnt out, I will take a 3-day detox.',
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (val) => notifier.updateGoalPlanning(goal.id, recoveryStrategy: val),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                for (var goal in bucketAGoals) {
                  final risk = _riskControllers[goal.id]?.text;
                  final rec = _recoveryControllers[goal.id]?.text;
                  await notifier.updateGoalPlanning(goal.id, failureRisk: risk, recoveryStrategy: rec);
                }
                _showFutureLetterDialog();
                setState(() => _planningStep = 3);
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('Next: Emotional Commitment'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyContractView(YearlyGoalsState state, YearlyGoalsNotifier notifier) {
    final bucketA = state.goals.where((g) => g.priorityBucket == 'A').toList();
    final bucketB = state.goals.where((g) => g.priorityBucket == 'B').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user, size: 64, color: Colors.indigo),
          const SizedBox(height: 16),
          const Text('2026 Yearly Contract', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Text('Strategy is Locked', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          _buildContractSection('The North Star', state.portfolioSummary ?? 'Focusing on skill acquisition and sustainable growth this year.'),
          const SizedBox(height: 24),
          _buildContractSection('The Big 3 (Bucket A)', ''),
          ...bucketA.map((g) => ListTile(
            title: Text(g.identityTitle ?? g.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Starting from Q${g.suggestedQuarter ?? 1}: ${g.baselineValue ?? "Not set"}'),
            leading: const Icon(Icons.star, color: Colors.amber),
          )),
          const SizedBox(height: 24),
          _buildContractSection('The Guardrails', ''),
          ...bucketA.where((g) => g.recoveryStrategy != null).map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text('IF ${g.failureRisk} ➔ THEN ${g.recoveryStrategy}', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
          )),
          const SizedBox(height: 48),
          const Divider(),
          const SizedBox(height: 24),
          const Text('Ready to take the first step?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement January Sprint logic
                context.go('/home');
              },
              icon: const Icon(Icons.rocket_launch),
              label: const Text('Build January Sprint'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.orange, foregroundColor: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _planningStep = 0),
            child: const Text('Exit to Dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _buildContractSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        if (content.isNotEmpty) Text(content, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildRealityAlert(double total, double capacity) {
    return const SizedBox.shrink();
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

  Widget _buildActionHeader(YearlyGoalsState state, YearlyGoalsNotifier notifier, bool isOver) {
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
                      final userReality = ref.read(userProvider).value;
                      if (userReality == null || !userReality.onboardingCompleted) {
                        _showOnboardingRequiredDialog();
                        return;
                      }
                      
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
                  : () => _handleFinalize(notifier, state, isOver),
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

    final isPreview = state.analysisResults.isNotEmpty;

    // Group goals by suggested quarter
    final quarters = <int, List<dynamic>>{
      1: [], 2: [], 3: [], 4: [],
    };
    
    // If we have analysis results, use them as a "Preview"
    if (isPreview) {
      for (final analysis in state.analysisResults) {
        final q = analysis.suggestedQuarter ?? 1;
        quarters[q]?.add(analysis);
      }
    } else {
      for (final goal in state.goals) {
        final q = goal.suggestedQuarter ?? 1;
        quarters[q]?.add(goal);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPreview)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo[100]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: Colors.indigo),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'PREVIEW: Drag goals between quarters to re-sequence. Click "Finalize" in Planning to save.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                  ),
                ],
              ),
            ),
          const Text(
            'Staggered Execution Plan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...[1, 2, 3, 4].map((q) {
            final items = quarters[q]!;
            return DragTarget<Object>(
              onWillAccept: (data) => true,
              onAccept: (data) {
                if (data is GoalAnalysis) {
                  notifier.updatePreviewQuarter(data.title, q);
                } else if (data is YearlyGoal) {
                  notifier.updateGoalQuarter(data.id, q);
                }
              },
              builder: (context, candidateData, rejectedData) {
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
                            decoration: BoxDecoration(
                              color: candidateData.isNotEmpty 
                                ? Colors.green 
                                : (isPreview ? Colors.indigo[300] : Colors.indigo),
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
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 40),
                      padding: const EdgeInsets.only(left: 52, bottom: 8),
                      decoration: BoxDecoration(
                        color: candidateData.isNotEmpty ? Colors.indigo.withOpacity(0.05) : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: items.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text('No goals scheduled for this quarter.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          )
                        : Column(
                            children: items.map((item) {
                              return LongPressDraggable<Object>(
                                data: item as Object,
                                feedback: Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: MediaQuery.of(context).size.width * 0.7,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.indigo),
                                    ),
                                    child: Text(
                                      item is YearlyGoal ? item.title : (item as GoalAnalysis).title,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.5,
                                  child: _buildRoadmapCard(item, notifier),
                                ),
                                child: _buildRoadmapCard(item, notifier),
                              );
                            }).toList(),
                          ),
                    ),
                  ],
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRoadmapCard(dynamic item, YearlyGoalsNotifier notifier) {
    final String title = item is YearlyGoal ? item.title : (item as GoalAnalysis).title;
    final String? bucket = item is YearlyGoal ? item.priorityBucket : (item as GoalAnalysis).priorityBucket;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          dense: true,
          title: Text(title),
          subtitle: bucket != null 
            ? Text('Bucket $bucket', style: TextStyle(color: _getBucketColor(bucket)))
            : null,
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (val) {
              if (item is GoalAnalysis) {
                notifier.updatePreviewBucket(title, val);
              } else if (item is YearlyGoal) {
                notifier.updateGoalBucket(item.id, val);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'A', child: Text('Move to Bucket A')),
              const PopupMenuItem(value: 'B', child: Text('Move to Bucket B')),
              const PopupMenuItem(value: 'C', child: Text('Move to Bucket C')),
            ],
          ),
        ),
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

  void _showOnboardingRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.psychology, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Reality Check Required'),
          ],
        ),
        content: const Text(
          'To tell you if these goals are realistic, Focura needs to know your weekly capacity and energy baseline first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/reality-check');
            },
            child: const Text('Tell Focura About My Week'),
          ),
        ],
      ),
    );
  }

  void _showFutureLetterDialog() {
    final letterController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.mail_outline, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Letter to Future Self'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Congratulations on finalizing your 2026 strategy! Write a letter to yourself that you will open on December 31, 2026.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: letterController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Dear Future Me, in 2026 I hope we achieved...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(context).pop(),
              child: const Text('Skip for now'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (letterController.text.trim().isEmpty) return;
                
                setDialogState(() => isSaving = true);
                final ok = await ref.read(yearlyGoalsProvider.notifier).saveFutureLetter(
                  letterController.text.trim(),
                );
                
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Letter sealed until Dec 31!' : 'Failed to save letter'),
                    ),
                  );
                }
              },
              child: isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Seal Letter'),
            ),
          ],
        ),
      ),
    );
  }
}

