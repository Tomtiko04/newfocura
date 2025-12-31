import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';

class OnboardingSurveyScreen extends ConsumerStatefulWidget {
  const OnboardingSurveyScreen({super.key});

  @override
  ConsumerState<OnboardingSurveyScreen> createState() => _OnboardingSurveyScreenState();
}

class _OnboardingSurveyScreenState extends ConsumerState<OnboardingSurveyScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Survey State
  double _weekdayHours = 2.0;
  double _weekendHours = 4.0;
  String _chronotype = 'morning';
  String _season = 'sustainability';
  int _reliability = 3;
  final List<TextEditingController> _antiGoalControllers = [TextEditingController()];

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _antiGoalControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    final antiGoals = _antiGoalControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final reality = RealityContext(
      weekdayFocusHours: _weekdayHours,
      weekendFocusHours: _weekendHours,
      energyChronotype: _chronotype,
      lifeSeason: _season,
      reliabilityScore: _reliability,
      antiGoals: antiGoals,
      onboardingCompleted: true,
    );

    final success = await ref.read(userProvider.notifier).updateOnboarding(reality);
    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save profile. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reality Check'),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (page) => setState(() => _currentPage = page),
        children: [
          _buildTimeBaselinePage(),
          _buildLifeContextPage(),
          _buildAntiGoalPage(),
          _buildSummaryPage(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _nextPage,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          child: Text(_currentPage == 3 ? 'Complete Reality Check' : 'Next'),
        ),
      ),
    );
  }

  Widget _buildTimeBaselinePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time & Energy Baseline',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'These numbers help the AI determine if your goals are realistic.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Text(
            'Weekday Deep Work Hours: ${_weekdayHours.toStringAsFixed(1)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text('Hours of uninterrupted focus on a typical weekday.'),
          Slider(
            value: _weekdayHours,
            min: 0,
            max: 12,
            divisions: 24,
            label: _weekdayHours.toString(),
            onChanged: (val) => setState(() => _weekdayHours = val),
          ),
          const SizedBox(height: 24),
          Text(
            'Weekend Warrior Capacity: ${_weekendHours.toStringAsFixed(1)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text('Total hours for Saturday + Sunday combined.'),
          Slider(
            value: _weekendHours,
            min: 0,
            max: 20,
            divisions: 40,
            label: _weekendHours.toString(),
            onChanged: (val) => setState(() => _weekendHours = val),
          ),
          const SizedBox(height: 24),
          const Text(
            'Energy Chronotype',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text('When are you most productive?'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'morning', label: Text('Early Bird')),
              ButtonSegment(value: 'afternoon', label: Text('Afternoon')),
              ButtonSegment(value: 'night', label: Text('Night Owl')),
            ],
            selected: {_chronotype},
            onSelectionChanged: (set) => setState(() => _chronotype = set.first),
          ),
        ],
      ),
    );
  }

  Widget _buildLifeContextPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Life Context',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          const Text(
            'Current Season',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          RadioListTile<String>(
            title: const Text('Push Season'),
            subtitle: const Text('Aggressive growth, sacrifice balance for a while.'),
            value: 'push',
            groupValue: _season,
            onChanged: (val) => setState(() => _season = val!),
          ),
          RadioListTile<String>(
            title: const Text('Sustainability Season'),
            subtitle: const Text('Protecting mental health and family time.'),
            value: 'sustainability',
            groupValue: _season,
            onChanged: (val) => setState(() => _season = val!),
          ),
          const SizedBox(height: 24),
          Text(
            'Reliability Score: $_reliability/5',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text('How often does "life" disrupt your plans?'),
          const SizedBox(height: 8),
          Slider(
            value: _reliability.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (val) => setState(() => _reliability = val.toInt()),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Highly Volatile', style: TextStyle(fontSize: 12)),
                Text('Very Stable', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAntiGoalPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The Not-To-Do List',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'To say "Yes" to your goals, you must say "No" to distractions.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ..._antiGoalControllers.asMap().entries.map((entry) {
            return Padding(
              key: ValueKey(entry.value),
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TextField(
                controller: entry.value,
                decoration: InputDecoration(
                  hintText: entry.key == 0 
                      ? 'e.g. Stop scrolling TikTok for 2 hours' 
                      : 'Add another distraction to avoid...',
                  prefixIcon: const Icon(Icons.block, color: Colors.red),
                  suffixIcon: _antiGoalControllers.length > 1
                      ? IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            setState(() {
                              final controller = _antiGoalControllers.removeAt(entry.key);
                              controller.dispose();
                            });
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
              ),
            );
          }),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _antiGoalControllers.add(TextEditingController());
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Constraint'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPage() {
    final weeklyTotal = (_weekdayHours * 5) + _weekendHours;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            'You\'re ready!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          _buildSummaryItem(Icons.timer, 'Weekly Capacity', '${weeklyTotal.toStringAsFixed(1)} hours'),
          _buildSummaryItem(Icons.wb_sunny, 'Chronotype', _chronotype.toUpperCase()),
          _buildSummaryItem(Icons.trending_up, 'Season', _season.toUpperCase()),
          _buildSummaryItem(Icons.shield, 'Stability', '$_reliability/5'),
          _buildSummaryItem(Icons.block, 'Anti-Goals', '${_antiGoalControllers.where((c) => c.text.isNotEmpty).length} items'),
          const SizedBox(height: 32),
          const Text(
            'Gemini will now use this "Math" to ensure your yearly goals are perfectly sequenced.',
            style: TextStyle(color: Colors.indigo, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}

