// lib/services/api_service.dart
import 'package:dio/dio.dart';
import '../models/user.dart';

class ApiService {
  final Dio _dio;
  
  // CHANGE THIS TO YOUR VPS IP/DOMAIN
  static const String baseUrl = 'http://YOUR_IRAN_VPS:3000/api';
  
  ApiService() : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<User?> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      
      if (response.data['success'] == true) {
        return User.fromJson(response.data['user']);
      }
      return null;
    } on DioException catch (e) {
      print('Login error: ${e.message}');
      return null;
    }
  }

  Future<User?> getUserStats(String username, String token) async {
    try {
      final response = await _dio.get(
        '/user/stats',
        queryParameters: {'username': username},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return User.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }
}
