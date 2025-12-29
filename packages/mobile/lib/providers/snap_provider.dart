import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class SnapResult {
  final String snapId;
  final Map<String, dynamic> result;
  final String vectorSyncStatus;

  SnapResult({
    required this.snapId,
    required this.result,
    required this.vectorSyncStatus,
  });
}

class SnapService {
  final ApiService _apiService;

  SnapService(this._apiService);

  Future<SnapResult> processSnap(String imagePath) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      // Use 10.0.2.2 for Android emulator to access host machine's localhost
      final baseUrl = Platform.isAndroid 
          ? 'http://10.0.2.2:3000/api/v1'
          : 'http://localhost:3000/api/v1';
      
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ));
      
      final response = await dio.post(
        '/snap/upload',
        data: formData,
      );

      if (response.statusCode == 200) {
        return SnapResult(
          snapId: response.data['snapId'],
          result: response.data['result'],
          vectorSyncStatus: response.data['vectorSyncStatus'] ?? 'pending',
        );
      } else {
        throw Exception('Failed to process snap');
      }
    } catch (e) {
      throw Exception('Error processing snap: $e');
    }
  }
}

final snapServiceProvider = Provider<SnapService>((ref) {
  return SnapService(apiService);
});

// FutureProvider for snap processing (shows loading animation)
final snapProcessingProvider = FutureProvider.family<SnapResult, String>((ref, imagePath) async {
  final service = ref.watch(snapServiceProvider);
  return await service.processSnap(imagePath);
});

