import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class Subtask {
  final String id;
  final String title;
  final int durationEstimate;
  final String status;
  final DateTime? completedAt;

  Subtask({
    required this.id,
    required this.title,
    required this.durationEstimate,
    required this.status,
    this.completedAt,
  });

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'],
      title: json['title'],
      durationEstimate: json['durationEstimate'],
      status: json['status'] ?? 'pending',
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }
}

class Task {
  final String id;
  final String? goalId;
  final String title;
  final String? description;
  final int priority;
  final String energyRequirement;
  final String implementationIntention;
  final String status;
  final DateTime? scheduledTime;
  final String? scheduledEnergyWindow;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final List<Subtask> subtasks;

  Task({
    required this.id,
    this.goalId,
    required this.title,
    this.description,
    required this.priority,
    required this.energyRequirement,
    required this.implementationIntention,
    required this.status,
    this.scheduledTime,
    this.scheduledEnergyWindow,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    required this.subtasks,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      goalId: json['goalId'],
      title: json['title'],
      description: json['description'],
      priority: json['priority'] ?? 3,
      energyRequirement: json['energyRequirement'] ?? 'Medium',
      implementationIntention: json['implementationIntention'] ?? '',
      status: json['status'] ?? 'pending',
      scheduledTime: json['scheduledTime'] != null ? DateTime.parse(json['scheduledTime']) : null,
      scheduledEnergyWindow: json['scheduledEnergyWindow'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      subtasks: (json['subtasks'] as List<dynamic>?)
          ?.map((st) => Subtask.fromJson(st))
          .toList() ?? [],
    );
  }
}

class TasksNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  final ApiService _apiService;

  TasksNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadTasks();
  }

  Future<void> loadTasks({String? status, String? energyRequirement}) async {
    try {
      state = const AsyncValue.loading();
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (energyRequirement != null) queryParams['energyRequirement'] = energyRequirement;

      final response = await _apiService.get('/tasks', queryParameters: queryParams.isEmpty ? null : queryParams);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final tasks = data.map((json) => Task.fromJson(json)).toList();
        state = AsyncValue.data(tasks);
      } else {
        state = AsyncValue.error('Failed to load tasks', StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> createTask({
    required String title,
    String? description,
    int? priority,
    String? energyRequirement,
    String? implementationIntention,
    String? goalId,
    List<Map<String, dynamic>>? subtasks,
  }) async {
    try {
      final data = <String, dynamic>{
        'title': title,
      };
      if (description != null && description.isNotEmpty) data['description'] = description;
      if (priority != null) data['priority'] = priority;
      if (energyRequirement != null) data['energyRequirement'] = energyRequirement;
      if (implementationIntention != null) data['implementationIntention'] = implementationIntention;
      if (goalId != null) data['goalId'] = goalId;
      if (subtasks != null && subtasks.isNotEmpty) data['subtasks'] = subtasks;

      final response = await _apiService.post('/tasks', data: data);
      if (response.statusCode == 201) {
        await loadTasks();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateTask(String id, {
    String? title,
    String? description,
    int? priority,
    String? status,
    String? energyRequirement,
    String? implementationIntention,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (priority != null) data['priority'] = priority;
      if (status != null) data['status'] = status;
      if (energyRequirement != null) data['energyRequirement'] = energyRequirement;
      if (implementationIntention != null) data['implementationIntention'] = implementationIntention;

      final response = await _apiService.put('/tasks/$id', data: data);
      if (response.statusCode == 200) {
        await loadTasks();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> completeSubtask(String taskId, String subtaskId) async {
    try {
      final response = await _apiService.post('/tasks/$taskId/subtasks/$subtaskId/complete');
      if (response.statusCode == 200) {
        await loadTasks();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTask(String id) async {
    try {
      final response = await _apiService.delete('/tasks/$id');
      if (response.statusCode == 200) {
        await loadTasks();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, AsyncValue<List<Task>>>((ref) {
  return TasksNotifier(apiService);
});

