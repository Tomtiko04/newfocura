import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class MomentumScore {
  final String id;
  final DateTime date;
  final bool consistency;
  final double energyAlignment;
  final double recovery;
  final double overallScore;
  final DateTime createdAt;

  MomentumScore({
    required this.id,
    required this.date,
    required this.consistency,
    required this.energyAlignment,
    required this.recovery,
    required this.overallScore,
    required this.createdAt,
  });

  factory MomentumScore.fromJson(Map<String, dynamic> json) {
    return MomentumScore(
      id: json['id'],
      date: DateTime.parse(json['date']),
      consistency: json['consistency'] ?? false,
      energyAlignment: (json['energyAlignment'] ?? 0.0).toDouble(),
      recovery: (json['recovery'] ?? 0.0).toDouble(),
      overallScore: (json['overallScore'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class MomentumData {
  final MomentumScore? score;
  final String? feedback;

  MomentumData({this.score, this.feedback});

  factory MomentumData.fromJson(Map<String, dynamic> json) {
    return MomentumData(
      score: json['score'] != null ? MomentumScore.fromJson(json['score']) : null,
      feedback: json['feedback'] is String ? json['feedback'] : null,
    );
  }
}

class MomentumNotifier extends StateNotifier<AsyncValue<MomentumData?>> {
  final ApiService _apiService;

  MomentumNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadTodayMomentum();
  }

  Future<void> loadTodayMomentum() async {
    try {
      state = const AsyncValue.loading();
      final response = await _apiService.get('/momentum/today');
      if (response.statusCode == 200) {
        final data = MomentumData.fromJson(response.data);
        state = AsyncValue.data(data);
      } else {
        state = AsyncValue.error('Failed to load momentum score', StackTrace.current);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> storeMomentumScore({DateTime? date}) async {
    try {
      final response = await _apiService.post('/momentum/store', data: {
        if (date != null) 'date': date.toIso8601String(),
      });

      if (response.statusCode == 200) {
        await loadTodayMomentum();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final momentumProvider = StateNotifierProvider<MomentumNotifier, AsyncValue<MomentumData?>>((ref) {
  return MomentumNotifier(apiService);
});

