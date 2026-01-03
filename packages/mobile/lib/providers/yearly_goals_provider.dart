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
  final String? baselineMetric;
  final String? baselineValue;
  final String? failureRisk;
  final String? recoveryStrategy;
  final String? aiBaselinePrompt;
  final String? identityTitle;

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
    this.baselineMetric,
    this.baselineValue,
    this.failureRisk,
    this.recoveryStrategy,
    this.aiBaselinePrompt,
    this.identityTitle,
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
    String? baselineMetric,
    String? baselineValue,
    String? failureRisk,
    String? recoveryStrategy,
    String? aiBaselinePrompt,
    String? identityTitle,
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
      baselineMetric: baselineMetric ?? this.baselineMetric,
      baselineValue: baselineValue ?? this.baselineValue,
      failureRisk: failureRisk ?? this.failureRisk,
      recoveryStrategy: recoveryStrategy ?? this.recoveryStrategy,
      aiBaselinePrompt: aiBaselinePrompt ?? this.aiBaselinePrompt,
      identityTitle: identityTitle ?? this.identityTitle,
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
      baselineMetric: json['baselineMetric'],
      baselineValue: json['baselineValue'],
      failureRisk: json['failureRisk'],
      recoveryStrategy: json['recoveryStrategy'],
      aiBaselinePrompt: json['aiBaselinePrompt'],
      identityTitle: json['identityTitle'],
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
  final String? aiBaselinePrompt;
  final String? identityTitle;

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
    this.aiBaselinePrompt,
    this.identityTitle,
  });

  GoalAnalysis copyWith({
    int? suggestedQuarter,
    String? priorityBucket,
  }) {
    return GoalAnalysis(
      title: title,
      why: why,
      startDate: startDate,
      endDate: endDate,
      feasibilityScore: feasibilityScore,
      feasibilityComment: feasibilityComment,
      strategicPivot: strategicPivot,
      estimatedHours: estimatedHours,
      impactScore: impactScore,
      priorityBucket: priorityBucket ?? this.priorityBucket,
      suggestedQuarter: suggestedQuarter ?? this.suggestedQuarter,
      aiBaselinePrompt: aiBaselinePrompt,
      identityTitle: identityTitle,
    );
  }
}

class YearlyGoalsState {
  final List<YearlyGoal> goals;
  final List<GoalAnalysis> analysisResults;
  final String? portfolioSummary;
  final bool isLoading;
  final String? error;

  YearlyGoalsState({
    this.goals = const [],
    this.analysisResults = const [],
    this.portfolioSummary,
    this.isLoading = false,
    this.error,
  });

  YearlyGoalsState copyWith({
    List<YearlyGoal>? goals,
    List<GoalAnalysis>? analysisResults,
    String? portfolioSummary,
    bool? isLoading,
    String? error,
  }) {
    return YearlyGoalsState(
      goals: goals ?? this.goals,
      analysisResults: analysisResults ?? this.analysisResults,
      portfolioSummary: portfolioSummary ?? this.portfolioSummary,
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
    String? aiBaselinePrompt,
    String? identityTitle,
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
      if (aiBaselinePrompt != null) data['aiBaselinePrompt'] = aiBaselinePrompt;
      if (identityTitle != null) data['identityTitle'] = identityTitle;

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
          aiBaselinePrompt: r['aiBaselinePrompt'],
          identityTitle: r['identityTitle'],
        );
      }).toList();
      state = state.copyWith(
        analysisResults: results,
        portfolioSummary: resp.data['summary'],
      );
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
        aiBaselinePrompt: match.aiBaselinePrompt,
        identityTitle: match.identityTitle,
        status: 'finalized',
      );
    }
    await loadGoals();
  }

  Future<bool> updateGoalPlanning(String id, {
    String? baselineMetric,
    String? baselineValue,
    String? failureRisk,
    String? recoveryStrategy,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (baselineMetric != null) data['baselineMetric'] = baselineMetric;
      if (baselineValue != null) data['baselineValue'] = baselineValue;
      if (failureRisk != null) data['failureRisk'] = failureRisk;
      if (recoveryStrategy != null) data['recoveryStrategy'] = recoveryStrategy;

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

  Future<void> importGoals(List<Map<String, String?>> items) async {
    for (final item in items) {
      await addGoal(
        title: item['title'] ?? 'Untitled Goal',
        why: item['why'],
      );
    }
    await loadGoals();
  }

  void updatePreviewQuarter(String title, int quarter) {
    state = state.copyWith(
      analysisResults: state.analysisResults.map((a) {
        if (a.title == title) return a.copyWith(suggestedQuarter: quarter);
        return a;
      }).toList(),
    );
  }

  void updatePreviewBucket(String title, String bucket) {
    state = state.copyWith(
      analysisResults: state.analysisResults.map((a) {
        if (a.title == title) return a.copyWith(priorityBucket: bucket);
        return a;
      }).toList(),
    );
  }

  Future<void> updateGoalQuarter(String id, int quarter) async {
    await updateGoal(id, suggestedQuarter: quarter);
  }

  Future<void> updateGoalBucket(String id, String bucket) async {
    await updateGoal(id, priorityBucket: bucket);
  }

  Future<bool> saveFutureLetter(String content) async {
    try {
      final resp = await _api.post('/letters', data: {'content': content});
      return resp.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}

final yearlyGoalsProvider = StateNotifierProvider<YearlyGoalsNotifier, YearlyGoalsState>((ref) {
  return YearlyGoalsNotifier(apiService);
});

