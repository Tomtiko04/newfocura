import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class RealityContext {
  final double weekdayFocusHours;
  final double weekendFocusHours;
  final String energyChronotype;
  final String lifeSeason;
  final int reliabilityScore;
  final List<String> antiGoals;
  final bool onboardingCompleted;

  RealityContext({
    required this.weekdayFocusHours,
    required this.weekendFocusHours,
    required this.energyChronotype,
    required this.lifeSeason,
    required this.reliabilityScore,
    required this.antiGoals,
    required this.onboardingCompleted,
  });

  factory RealityContext.fromJson(Map<String, dynamic> json) {
    return RealityContext(
      weekdayFocusHours: (json['weekdayFocusHours'] as num).toDouble(),
      weekendFocusHours: (json['weekendFocusHours'] as num).toDouble(),
      energyChronotype: json['energyChronotype'] ?? 'morning',
      lifeSeason: json['lifeSeason'] ?? 'sustainability',
      reliabilityScore: json['reliabilityScore'] ?? 3,
      antiGoals: List<String>.from(json['antiGoals'] ?? []),
      onboardingCompleted: json['onboardingCompleted'] ?? false,
    );
  }

  RealityContext copyWith({
    double? weekdayFocusHours,
    double? weekendFocusHours,
    String? energyChronotype,
    String? lifeSeason,
    int? reliabilityScore,
    List<String>? antiGoals,
    bool? onboardingCompleted,
  }) {
    return RealityContext(
      weekdayFocusHours: weekdayFocusHours ?? this.weekdayFocusHours,
      weekendFocusHours: weekendFocusHours ?? this.weekendFocusHours,
      energyChronotype: energyChronotype ?? this.energyChronotype,
      lifeSeason: lifeSeason ?? this.lifeSeason,
      reliabilityScore: reliabilityScore ?? this.reliabilityScore,
      antiGoals: antiGoals ?? this.antiGoals,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}

class UserNotifier extends StateNotifier<AsyncValue<RealityContext?>> {
  final ApiService _api;

  UserNotifier(this._api) : super(const AsyncValue.loading()) {
    loadReality();
  }

  Future<void> loadReality() async {
    try {
      final resp = await _api.get('/user/reality');
      if (resp.statusCode == 200) {
        state = AsyncValue.data(RealityContext.fromJson(resp.data));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> updateOnboarding(RealityContext reality) async {
    try {
      final resp = await _api.put('/user/onboarding', data: {
        'weekdayFocusHours': reality.weekdayFocusHours,
        'weekendFocusHours': reality.weekendFocusHours,
        'energyChronotype': reality.energyChronotype,
        'lifeSeason': reality.lifeSeason,
        'reliabilityScore': reality.reliabilityScore,
        'antiGoals': reality.antiGoals,
      });

      if (resp.statusCode == 200) {
        state = AsyncValue.data(reality.copyWith(onboardingCompleted: true));
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<RealityContext?>>((ref) {
  return UserNotifier(apiService);
});

