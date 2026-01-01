import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late final Dio _dio;
  
  // Backend URL configuration
  // Set this to null for auto-detection (emulator/simulator)
  // For physical devices, set to your computer's local IP: 'http://192.168.1.XXX:3000/api/v1'
  // Or use your Render backend URL if deployed: 'https://your-backend.onrender.com/api/v1'
  // 
  // IMPORTANT: Use your COMPUTER's IP address (where backend runs), NOT your phone's IP
  // Phone IP: 172.20.10.3 (this is what you DON'T use)
  // Computer IP: 172.20.10.5 (this is what you DO use - where backend server runs)
  static const String? _manualBaseUrl = 'http://172.20.10.5:3000/api/v1';
  
  // Use 10.0.2.2 for Android emulator to access host machine's localhost
  // Use localhost for iOS simulator and web
  // For physical devices, use local IP or Render backend URL
  static String get baseUrl {
    // Manual override (for physical devices or production)
    if (_manualBaseUrl != null) {
      return _manualBaseUrl!;
    }
    
    // Auto-detect for emulator/simulator
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/v1'; // Android emulator
    } else {
      return 'http://localhost:3000/api/v1'; // iOS simulator / web
    }
  }

  ApiService() {
    final url = ApiService.baseUrl;
    print('ApiService initialized with baseUrl: $url');
    print('Platform.isAndroid: ${Platform.isAndroid}');
    
    _dio = Dio(
      BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Handle unauthorized
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }

  Future<Response> uploadFile(
    String path,
    String filePath,
    String fieldName,
  ) async {
    return _dio.post(
      path,
      data: FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
      }),
    );
  }
}

final apiService = ApiService();

