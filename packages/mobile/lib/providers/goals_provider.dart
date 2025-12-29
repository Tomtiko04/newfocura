import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class Goal {
  final String id;
  final String title;
  final String? description;
  final DateTime deadline;
  final double? feasibilityScore;
  final String? feasibilityAnalysis;
  final String? strategicPivot;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Goal({
    required this.id,
    required this.title,
    this.description,
    required this.deadline,
    this.feasibilityScore,
    this.feasibilityAnalysis,
    this.strategicPivot,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      deadline: DateTime.parse(json['deadline']),
      feasibilityScore: json['feasibilityScore']?.toDouble(),
      feasibilityAnalysis: json['feasibilityAnalysis'],
      strategicPivot: json['strategicPivot'],
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class GoalsNotifier extends StateNotifier<AsyncValue<List<Goal>>> {
  final ApiService _apiService;

  GoalsNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    try {
      state = const AsyncValue.loading();
      final response = await _apiService.get('/goals');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final goals = data.map((json) => Goal.fromJson(json)).toList();
        state = AsyncValue.data(goals);
      } else {
        state = AsyncValue.error('Failed to load goals', StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> createGoal({
    required String title,
    String? description,
    required DateTime deadline,
  }) async {
    try {
      final response = await _apiService.post('/goals', data: {
        'title': title,
        if (description != null && description.isNotEmpty) 'description': description,
        'deadline': deadline.toIso8601String(),
      });

      if (response.statusCode == 201) {
        await loadGoals();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateGoal(String id, {
    String? title,
    String? description,
    DateTime? deadline,
    String? status,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (deadline != null) data['deadline'] = deadline.toIso8601String();
      if (status != null) data['status'] = status;

      final response = await _apiService.put('/goals/$id', data: data);
      if (response.statusCode == 200) {
        await loadGoals();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteGoal(String id) async {
    try {
      final response = await _apiService.delete('/goals/$id');
      if (response.statusCode == 200) {
        await loadGoals();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final goalsProvider = StateNotifierProvider<GoalsNotifier, AsyncValue<List<Goal>>>((ref) {
  return GoalsNotifier(apiService);
});

