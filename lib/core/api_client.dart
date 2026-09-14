import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Set per flavor: --dart-define=API_URL=https://api.jobsmator.app
const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3001');

/// Error shape from the API: { error, message, details? }.
class ApiException implements Exception {
  ApiException(this.code, this.message, {this.status});
  final String code;
  final String message;
  final int? status;
  @override
  String toString() => '$code: $message';
}

class ApiClient {
  ApiClient({required Future<String?> Function() tokenProvider})
      : _dio = Dio(BaseOptions(baseUrl: apiUrl, connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 20))) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenProvider();
        if (token != null) options.headers['authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (e, handler) {
        final data = e.response?.data;
        if (data is Map && data['error'] is String) {
          handler.reject(DioException(requestOptions: e.requestOptions, error: ApiException(data['error'], data['message'] ?? '', status: e.response?.statusCode)));
        } else {
          handler.reject(DioException(requestOptions: e.requestOptions, error: ApiException('network', 'Check your connection and try again.')));
        }
      },
    ));
    if (kDebugMode) _dio.interceptors.add(LogInterceptor(requestBody: false, responseBody: false));
  }

  final Dio _dio;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async =>
      _unwrap(await _dio.get(path, queryParameters: query));
  Future<Map<String, dynamic>> post(String path, {Object? body}) async => _unwrap(await _dio.post(path, data: body));
  Future<Map<String, dynamic>> patch(String path, {Object? body}) async => _unwrap(await _dio.patch(path, data: body));
  Future<void> delete(String path) => _dio.delete(path);

  Map<String, dynamic> _unwrap(Response r) => (r.data as Map?)?.cast<String, dynamic>() ?? const {};
}
