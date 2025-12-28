import 'package:flutter/material.dart';

class MorningSyncScreen extends StatefulWidget {
  const MorningSyncScreen({super.key});

  @override
  State<MorningSyncScreen> createState() => _MorningSyncScreenState();
}

class _MorningSyncScreenState extends State<MorningSyncScreen> {
  DateTime? _sleepTime;
  DateTime? _wakeTime;
  double _initialFocus = 3.0;

  Future<void> _selectSleepTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        _sleepTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      });
    }
  }

  Future<void> _selectWakeTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        _wakeTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      });
    }
  }

  void _submitMorningSync() {
    if (_sleepTime == null || _wakeTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both sleep and wake times')),
      );
      return;
    }

    // TODO: Submit to API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Morning sync submitted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Morning Sync'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '30-Second Check-in',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            ListTile(
              title: const Text('Sleep Time'),
              subtitle: Text(_sleepTime != null
                  ? '${_sleepTime!.hour}:${_sleepTime!.minute.toString().padLeft(2, '0')}'
                  : 'Not set'),
              trailing: const Icon(Icons.access_time),
              onTap: _selectSleepTime,
            ),
            ListTile(
              title: const Text('Wake Time'),
              subtitle: Text(_wakeTime != null
                  ? '${_wakeTime!.hour}:${_wakeTime!.minute.toString().padLeft(2, '0')}'
                  : 'Not set'),
              trailing: const Icon(Icons.access_time),
              onTap: _selectWakeTime,
            ),
            const SizedBox(height: 24),
            Text(
              'Initial Focus (1-5)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
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
            const SizedBox(height: 32),
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
    );
  }
}

