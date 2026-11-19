import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/token_storage.dart';

class AuthService {
  final Dio _dio = ApiClient.dio;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/signin',
        data: {'email': email, 'password': password},
      );

      final result = Map<String, dynamic>.from(response.data);
      final data = Map<String, dynamic>.from(result['data']);

      final token = data['token'] as String?;

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      await TokenStorage.saveToken(token);

      return result;
    } on DioException catch (e) {
      final message = e.response?.data?['message'];
      throw Exception(message ?? 'Unable to login');
    }
  }

  // Get currently logged-in user
  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _dio.post('/auth/me');

      final result = Map<String, dynamic>.from(response.data);
      final data = Map<String, dynamic>.from(result['data']);

      return data;
    } on DioException catch (e) {
      final message = e.response?.data?['message'];
      throw Exception(message ?? 'Unable to get user data');
    }
  }

  Future<void> logout() async {
    await TokenStorage.deleteToken();
  }

  Future<bool> checkAuth() async {
    try {
      final response = await _dio.post('/auth/me');

      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await TokenStorage.deleteToken();
      }

      debugPrint('Check auth failed: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected auth error: $e');
      return false;
    }
  }
}
