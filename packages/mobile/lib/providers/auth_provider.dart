import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  final String? userId;
  final String? email;
  final String? name;
  final bool isLoading;

  AuthState({
    this.userId,
    this.email,
    this.name,
    this.isLoading = false,
  });

  bool get isAuthenticated => userId != null;

  AuthState copyWith({
    String? userId,
    String? email,
    String? name,
    bool? isLoading,
  }) {
    return AuthState(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;

  AuthNotifier(this._apiService) : super(AuthState()) {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      try {
        final response = await _apiService.get('/auth/me');
        if (response.statusCode == 200) {
          final user = response.data['user'];
          state = AuthState(
            userId: user['id'],
            email: user['email'],
            name: user['name'],
          );
        }
      } catch (e) {
        // Token invalid, clear it
        await prefs.remove('auth_token');
      }
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiService.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final user = response.data['user'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        state = AuthState(
          userId: user['id'],
          email: user['email'],
          name: user['name'],
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> register(String email, String password, String? name) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiService.post('/auth/register', data: {
        'email': email,
        'password': password,
        if (name != null) 'name': name,
      });

      if (response.statusCode == 201) {
        final token = response.data['token'];
        final user = response.data['user'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        state = AuthState(
          userId: user['id'],
          email: user['email'],
          name: user['name'],
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    state = AuthState();
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(apiService);
});

