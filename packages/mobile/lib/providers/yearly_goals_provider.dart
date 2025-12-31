import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'package:dio/dio.dart';

class YearlyGoal {
  final String id;
  final String title;
  final String? why;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? feasibilityScore;
  final String? feasibilityComment;
  final String? strategicPivot;
  final double? estimatedHours;
  final double? impactScore;
  final String? priorityBucket;
  final int? suggestedQuarter;
  final String? skillLevel;
  final int? priorityOrder;
  final String status; // draft, analyzed, finalized

  YearlyGoal({
    required this.id,
    required this.title,
    this.why,
    this.startDate,
    this.endDate,
    this.feasibilityScore,
    this.feasibilityComment,
    this.strategicPivot,
    this.estimatedHours,
    this.impactScore,
    this.priorityBucket,
    this.suggestedQuarter,
    this.skillLevel,
    this.priorityOrder,
    required this.status,
  });

  YearlyGoal copyWith({
    String? title,
    String? why,
    DateTime? startDate,
    DateTime? endDate,
    double? feasibilityScore,
    String? feasibilityComment,
    String? strategicPivot,
    double? estimatedHours,
    double? impactScore,
    String? priorityBucket,
    int? suggestedQuarter,
    String? skillLevel,
    int? priorityOrder,
    String? status,
  }) {
    return YearlyGoal(
      id: id,
      title: title ?? this.title,
      why: why ?? this.why,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      feasibilityScore: feasibilityScore ?? this.feasibilityScore,
      feasibilityComment: feasibilityComment ?? this.feasibilityComment,
      strategicPivot: strategicPivot ?? this.strategicPivot,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      impactScore: impactScore ?? this.impactScore,
      priorityBucket: priorityBucket ?? this.priorityBucket,
      suggestedQuarter: suggestedQuarter ?? this.suggestedQuarter,
      skillLevel: skillLevel ?? this.skillLevel,
      priorityOrder: priorityOrder ?? this.priorityOrder,
      status: status ?? this.status,
    );
  }

  factory YearlyGoal.fromJson(Map<String, dynamic> json) {
    return YearlyGoal(
      id: json['id'],
      title: json['title'],
      why: json['why'],
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      feasibilityScore: (json['feasibilityScore'] as num?)?.toDouble(),
      feasibilityComment: json['feasibilityComment'],
      strategicPivot: json['strategicPivot'],
      estimatedHours: (json['estimatedHours'] as num?)?.toDouble(),
      impactScore: (json['impactScore'] as num?)?.toDouble(),
      priorityBucket: json['priorityBucket'],
      suggestedQuarter: json['suggestedQuarter'],
      skillLevel: json['skillLevel'],
      priorityOrder: json['priorityOrder'],
      status: json['status'] ?? 'draft',
    );
  }
}

class GoalAnalysis {
  final String title;
  final String? why;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? feasibilityScore;
  final String? feasibilityComment;
  final String? strategicPivot;
  final double? estimatedHours;
  final double? impactScore;
  final String? priorityBucket;
  final int? suggestedQuarter;

  GoalAnalysis({
    required this.title,
    this.why,
    this.startDate,
    this.endDate,
    this.feasibilityScore,
    this.feasibilityComment,
    this.strategicPivot,
    this.estimatedHours,
    this.impactScore,
    this.priorityBucket,
    this.suggestedQuarter,
  });
}

class YearlyGoalsState {
  final List<YearlyGoal> goals;
  final List<GoalAnalysis> analysisResults;
  final bool isLoading;
  final String? error;

  YearlyGoalsState({
    this.goals = const [],
    this.analysisResults = const [],
    this.isLoading = false,
    this.error,
  });

  YearlyGoalsState copyWith({
    List<YearlyGoal>? goals,
    List<GoalAnalysis>? analysisResults,
    bool? isLoading,
    String? error,
  }) {
    return YearlyGoalsState(
      goals: goals ?? this.goals,
      analysisResults: analysisResults ?? this.analysisResults,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class YearlyGoalsNotifier extends StateNotifier<YearlyGoalsState> {
  final ApiService _api;

  YearlyGoalsNotifier(this._api) : super(YearlyGoalsState()) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _api.get('/yearly-goals');
      final data = resp.data as List<dynamic>;
      final goals = data.map((g) => YearlyGoal.fromJson(g)).toList();
      state = state.copyWith(goals: goals, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load yearly goals');
    }
  }

  Future<bool> addGoal({
    required String title,
    String? why,
    DateTime? startDate,
    DateTime? endDate,
    String? skillLevel,
  }) async {
    try {
      // Debug logging
      // ignore: avoid_print
      print('Adding yearly goal: title=$title, why=$why, start=$startDate, end=$endDate, skill=$skillLevel');
      final resp = await _api.post('/yearly-goals', data: {
        'title': title,
        if (why != null && why.isNotEmpty) 'why': why,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (skillLevel != null) 'skillLevel': skillLevel,
      });
      if (resp.statusCode == 201) {
        await loadGoals();
        return true;
      }
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Add yearly goal error: $e');
      if (e is DioException) {
        // ignore: avoid_print
        print('Response: ${e.response?.data}, status: ${e.response?.statusCode}');
      }
      return false;
    }
  }

  Future<bool> updateGoal(String id, {
    String? title,
    String? why,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    double? feasibilityScore,
    String? feasibilityComment,
    String? strategicPivot,
    double? estimatedHours,
    double? impactScore,
    String? priorityBucket,
    int? suggestedQuarter,
    String? skillLevel,
    int? priorityOrder,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (why != null) data['why'] = why;
      if (status != null) data['status'] = status;
      if (startDate != null) data['startDate'] = startDate.toIso8601String();
      if (endDate != null) data['endDate'] = endDate.toIso8601String();
      if (feasibilityScore != null) data['feasibilityScore'] = feasibilityScore;
      if (feasibilityComment != null) data['feasibilityComment'] = feasibilityComment;
      if (strategicPivot != null) data['strategicPivot'] = strategicPivot;
      if (estimatedHours != null) data['estimatedHours'] = estimatedHours;
      if (impactScore != null) data['impactScore'] = impactScore;
      if (priorityBucket != null) data['priorityBucket'] = priorityBucket;
      if (suggestedQuarter != null) data['suggestedQuarter'] = suggestedQuarter;
      if (skillLevel != null) data['skillLevel'] = skillLevel;
      if (priorityOrder != null) data['priorityOrder'] = priorityOrder;

      final resp = await _api.put('/yearly-goals/$id', data: data);
      if (resp.statusCode == 200) {
        await loadGoals();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteGoal(String id) async {
    try {
      final resp = await _api.delete('/yearly-goals/$id');
      if (resp.statusCode == 200) {
        await loadGoals();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<List<GoalAnalysis>> analyzeAll() async {
    try {
      final payload = {
        'goals': state.goals.map((g) => {
          'title': g.title,
          'why': g.why,
          'startDate': g.startDate?.toIso8601String(),
          'endDate': g.endDate?.toIso8601String(),
        }).toList(),
      };
      // ignore: avoid_print
      print('Analyze yearly goals payload: $payload');
      final resp = await _api.post('/yearly-goals/feasibility', data: payload);
      // ignore: avoid_print
      print('Analyze response status: ${resp.statusCode}, data: ${resp.data}');
      if (resp.statusCode != 200 || resp.data['results'] == null) {
        throw Exception('Server returned error: ${resp.statusCode}');
      }
      final results = (resp.data['results'] as List<dynamic>).map((r) {
        return GoalAnalysis(
          title: r['title'],
          why: r['why'],
          startDate: r['startDate'] != null ? DateTime.parse(r['startDate']) : null,
          endDate: r['endDate'] != null ? DateTime.parse(r['endDate']) : null,
          feasibilityScore: (r['feasibilityScore'] as num?)?.toDouble(),
          feasibilityComment: r['feasibilityComment'],
          strategicPivot: r['strategicPivot'],
          estimatedHours: (r['estimatedHours'] as num?)?.toDouble(),
          impactScore: (r['impactScore'] as num?)?.toDouble(),
          priorityBucket: r['priorityBucket'],
          suggestedQuarter: r['suggestedQuarter'],
        );
      }).toList();
      state = state.copyWith(analysisResults: results);
      return results;
    } catch (e) {
      // ignore: avoid_print
      print('Analyze all error: $e');
      rethrow;
    }
  }

  Future<void> finalizeAllWithAnalysis(List<GoalAnalysis> analyses) async {
    // Apply analysis results to each goal and mark as finalized
    for (final goal in state.goals) {
      final match = analyses.firstWhere(
        (a) => a.title == goal.title,
        orElse: () => GoalAnalysis(title: goal.title),
      );
      await updateGoal(
        goal.id,
        feasibilityScore: match.feasibilityScore,
        feasibilityComment: match.feasibilityComment,
        strategicPivot: match.strategicPivot,
        estimatedHours: match.estimatedHours,
        impactScore: match.impactScore,
        priorityBucket: match.priorityBucket,
        suggestedQuarter: match.suggestedQuarter,
        status: 'finalized',
      );
    }
    await loadGoals();
  }

  Future<void> importGoals(List<Map<String, String?>> items) async {
    for (final item in items) {
      await addGoal(
        title: item['title'] ?? 'Untitled Goal',
        why: item['why'],
      );
    }
    await loadGoals();
  }
}

final yearlyGoalsProvider = StateNotifierProvider<YearlyGoalsNotifier, YearlyGoalsState>((ref) {
  return YearlyGoalsNotifier(apiService);
});

