import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class Schedule {
  final Map<String, dynamic> tasks;
  final Map<String, dynamic> energyWindows;
  final DateTime date;

  Schedule({
    required this.tasks,
    required this.energyWindows,
    required this.date,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      tasks: json['tasks'] ?? {},
      energyWindows: json['energyWindows'] ?? {},
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }

  List<String> get morningPeakTasks => (energyWindows['morning_peak'] as List<dynamic>?)
      ?.map((e) => e.toString())
      .toList() ?? [];

  List<String> get afternoonAdminTasks => (energyWindows['afternoon_admin'] as List<dynamic>?)
      ?.map((e) => e.toString())
      .toList() ?? [];

  List<String> get eveningReflectionTasks => (energyWindows['evening_reflection'] as List<dynamic>?)
      ?.map((e) => e.toString())
      .toList() ?? [];
}

class ScheduleNotifier extends StateNotifier<AsyncValue<Schedule?>> {
  final ApiService _apiService;

  ScheduleNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadTodaySchedule();
  }

  Future<void> loadTodaySchedule() async {
    try {
      state = const AsyncValue.loading();
      final response = await _apiService.get('/schedule/today');
      if (response.statusCode == 200) {
        final schedule = Schedule.fromJson(response.data);
        state = AsyncValue.data(schedule);
      } else {
        state = AsyncValue.error('Failed to load schedule', StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> generateSchedule({DateTime? date}) async {
    try {
      state = const AsyncValue.loading();
      final response = await _apiService.post('/schedule/generate', data: {
        if (date != null) 'date': date.toIso8601String(),
      });

      if (response.statusCode == 200) {
        final schedule = Schedule.fromJson(response.data);
        state = AsyncValue.data(schedule);
        return true;
      }
      state = AsyncValue.error('Failed to generate schedule', StackTrace.current);
      return false;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }
}

final scheduleProvider = StateNotifierProvider<ScheduleNotifier, AsyncValue<Schedule?>>((ref) {
  return ScheduleNotifier(apiService);
});

