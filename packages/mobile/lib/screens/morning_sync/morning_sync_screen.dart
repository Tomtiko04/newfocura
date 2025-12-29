import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/morning_sync_provider.dart';

class MorningSyncScreen extends ConsumerStatefulWidget {
  const MorningSyncScreen({super.key});

  @override
  ConsumerState<MorningSyncScreen> createState() => _MorningSyncScreenState();
}

class _MorningSyncScreenState extends ConsumerState<MorningSyncScreen> {
  DateTime? _sleepTime;
  DateTime? _wakeTime;
  double _initialFocus = 3.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTodaySync();
    });
  }

  Future<void> _loadTodaySync() async {
    final syncAsync = ref.read(morningSyncProvider);
    syncAsync.whenData((sync) {
      if (sync != null && mounted) {
        setState(() {
          _sleepTime = sync.sleepTime;
          _wakeTime = sync.wakeTime;
          _initialFocus = sync.initialFocus.toDouble();
        });
      }
    });
  }

  Future<void> _selectSleepTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _sleepTime != null
          ? TimeOfDay.fromDateTime(_sleepTime!)
          : const TimeOfDay(hour: 22, minute: 0),
    );
    if (picked != null && mounted) {
      setState(() {
        final now = DateTime.now();
        _sleepTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      });
    }
  }

  Future<void> _selectWakeTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _wakeTime != null
          ? TimeOfDay.fromDateTime(_wakeTime!)
          : const TimeOfDay(hour: 7, minute: 0),
    );
    if (picked != null && mounted) {
      setState(() {
        final now = DateTime.now();
        _wakeTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      });
    }
  }

  Future<void> _submitMorningSync() async {
    if (_sleepTime == null || _wakeTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both sleep and wake times')),
      );
      return;
    }

    // Ensure sleep time is yesterday if it's before wake time
    DateTime sleepTime = _sleepTime!;
    if (sleepTime.isAfter(_wakeTime!)) {
      sleepTime = sleepTime.subtract(const Duration(days: 1));
    }

    final success = await ref.read(morningSyncProvider.notifier).submitMorningSync(
          sleepTime: sleepTime,
          wakeTime: _wakeTime!,
          initialFocus: _initialFocus.round(),
        );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Morning sync submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Show analysis if available
        final syncAsync = ref.read(morningSyncProvider);
        syncAsync.whenData((sync) {
          if (sync != null && mounted) {
            _showAnalysisDialog(sync);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit morning sync'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAnalysisDialog(MorningSync sync) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Morning Sync Analysis'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sync.sleepDebt != null) ...[
                Text(
                  'Sleep Debt',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text('${sync.sleepDebt!.toStringAsFixed(1)} hours'),
                const SizedBox(height: 16),
              ],
              if (sync.sleepInertia != null) ...[
                Text(
                  'Sleep Inertia',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text('${sync.sleepInertia} minutes until peak focus'),
                const SizedBox(height: 16),
              ],
              if (sync.energyBaseline != null) ...[
                Text(
                  'Energy Baseline',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                LinearProgressIndicator(
                  value: sync.energyBaseline! / 5,
                  backgroundColor: Colors.grey[300],
                ),
                Text('${sync.energyBaseline!.toStringAsFixed(1)}/5'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final syncAsync = ref.watch(morningSyncProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Morning Sync'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: syncAsync.when(
        data: (sync) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '30-Second Check-in',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Help AI understand your energy patterns',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              Card(
                child: ListTile(
                  title: const Text('Sleep Time'),
                  subtitle: Text(_sleepTime != null
                      ? '${_sleepTime!.hour}:${_sleepTime!.minute.toString().padLeft(2, '0')}'
                      : 'Not set'),
                  trailing: const Icon(Icons.access_time),
                  onTap: _selectSleepTime,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  title: const Text('Wake Time'),
                  subtitle: Text(_wakeTime != null
                      ? '${_wakeTime!.hour}:${_wakeTime!.minute.toString().padLeft(2, '0')}'
                      : 'Not set'),
                  trailing: const Icon(Icons.access_time),
                  onTap: _selectWakeTime,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Initial Focus (1-5)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _initialFocus,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _initialFocus.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          _initialFocus = value;
                        });
                      },
                    ),
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      _initialFocus.round().toString(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (sync != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Sync completed today',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                          ),
                        ],
                      ),
                      if (sync.sleepDebt != null || sync.energyBaseline != null) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => _showAnalysisDialog(sync),
                          child: const Text('View Analysis'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: _submitMorningSync,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Submit Morning Sync'),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(morningSyncProvider.notifier).loadTodaySync(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
