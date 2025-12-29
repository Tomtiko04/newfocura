import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class MorningSync {
  final String id;
  final DateTime date;
  final DateTime sleepTime;
  final DateTime wakeTime;
  final int initialFocus;
  final double? sleepDebt;
  final int? sleepInertia;
  final double? energyBaseline;
  final List<dynamic>? actualPeaks;

  MorningSync({
    required this.id,
    required this.date,
    required this.sleepTime,
    required this.wakeTime,
    required this.initialFocus,
    this.sleepDebt,
    this.sleepInertia,
    this.energyBaseline,
    this.actualPeaks,
  });

  factory MorningSync.fromJson(Map<String, dynamic> json) {
    return MorningSync(
      id: json['id'],
      date: DateTime.parse(json['date']),
      sleepTime: DateTime.parse(json['sleepTime']),
      wakeTime: DateTime.parse(json['wakeTime']),
      initialFocus: json['initialFocus'],
      sleepDebt: json['sleepDebt']?.toDouble(),
      sleepInertia: json['sleepInertia'],
      energyBaseline: json['energyBaseline']?.toDouble(),
      actualPeaks: json['actualPeaks'],
    );
  }
}

class MorningSyncNotifier extends StateNotifier<AsyncValue<MorningSync?>> {
  final ApiService _apiService;

  MorningSyncNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadTodaySync();
  }

  Future<void> loadTodaySync() async {
    try {
      state = const AsyncValue.loading();
      final response = await _apiService.get('/morning-sync/today');
      if (response.statusCode == 200) {
        if (response.data != null) {
          final sync = MorningSync.fromJson(response.data);
          state = AsyncValue.data(sync);
        } else {
          state = const AsyncValue.data(null);
        }
      } else {
        state = AsyncValue.error('Failed to load morning sync', StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> submitMorningSync({
    required DateTime sleepTime,
    required DateTime wakeTime,
    required int initialFocus,
  }) async {
    try {
      state = const AsyncValue.loading();
      final response = await _apiService.post('/morning-sync', data: {
        'sleepTime': sleepTime.toIso8601String(),
        'wakeTime': wakeTime.toIso8601String(),
        'initialFocus': initialFocus,
      });

      if (response.statusCode == 200) {
        final sync = MorningSync.fromJson(response.data['bioSync']);
        state = AsyncValue.data(sync);
        return true;
      }
      state = AsyncValue.error('Failed to submit morning sync', StackTrace.current);
      return false;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Future<bool> recordPeak(DateTime timestamp) async {
    try {
      final response = await _apiService.post('/morning-sync/peaks', data: {
        'timestamp': timestamp.toIso8601String(),
      });

      if (response.statusCode == 200) {
        await loadTodaySync();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final morningSyncProvider = StateNotifierProvider<MorningSyncNotifier, AsyncValue<MorningSync?>>((ref) {
  return MorningSyncNotifier(apiService);
});

