import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
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
            isLoading: false,
          );
        }
      } catch (e) {
        print('Load auth state error: $e');
        // Token invalid, clear it
        await prefs.remove('auth_token');
      }
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      print('Attempting login for: $email');
      final response = await _apiService.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      print('Login response status: ${response.statusCode}');
      print('Login response data: ${response.data}');

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final user = response.data['user'];

        if (token == null) {
          print('No token in response');
          state = state.copyWith(isLoading: false);
          return false;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        state = AuthState(
          userId: user['id'],
          email: user['email'],
          name: user['name'],
          isLoading: false,
        );
        print('Login successful, userId: ${user['id']}');
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      print('Login error: $e');
      if (e is DioException) {
        print('Dio error: ${e.message}');
        print('Response: ${e.response?.data}');
        print('Status: ${e.response?.statusCode}');
      }
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> register(String email, String password, String? name) async {
    state = state.copyWith(isLoading: true);
    try {
      print('Attempting registration for: $email');
      final response = await _apiService.post('/auth/register', data: {
        'email': email,
        'password': password,
        if (name != null && name.isNotEmpty) 'name': name,
      });

      print('Register response status: ${response.statusCode}');
      print('Register response data: ${response.data}');

      if (response.statusCode == 201) {
        final token = response.data['token'];
        final user = response.data['user'];

        if (token == null) {
          print('No token in response');
          state = state.copyWith(isLoading: false);
          return false;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        state = AuthState(
          userId: user['id'],
          email: user['email'],
          name: user['name'],
          isLoading: false,
        );
        print('Registration successful, userId: ${user['id']}');
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      print('Register error: $e');
      if (e is DioException) {
        print('Dio error: ${e.message}');
        print('Response: ${e.response?.data}');
        print('Status: ${e.response?.statusCode}');
      }
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
