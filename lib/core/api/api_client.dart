import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';

/// Error shape from the API: `{ error, message, details? }`.
/// `code` is stable (see ARCHITECTURE.md §9); `message` is a human sentence.
class ApiException implements Exception {
  ApiException(this.code, this.message, {this.status});
  final String code;
  final String message;
  final int? status;

  @override
  String toString() => '$code: $message';
}

/// Thin JSON transport. Providers speak paths and maps; nothing above this
/// layer knows about Dio, so [MockApiClient] can stand in for design work.
abstract class ApiClient {
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query});
  Future<Map<String, dynamic>> post(String path, {Object? body});
  Future<Map<String, dynamic>> patch(String path, {Object? body});
  Future<void> delete(String path);
}

class HttpApiClient implements ApiClient {
  HttpApiClient({required Future<String?> Function() tokenProvider})
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenProvider();
          if (token != null) options.headers['authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (e, handler) {
          final data = e.response?.data;
          final err = data is Map && data['error'] is String
              ? ApiException(data['error'], data['message'] ?? '', status: e.response?.statusCode)
              : ApiException('network', 'Check your connection and try again.');
          handler.reject(DioException(requestOptions: e.requestOptions, error: err));
        },
      ),
    );
    if (kDebugMode) _dio.interceptors.add(LogInterceptor(requestBody: false, responseBody: false));
  }

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _run(() => _dio.get(path, queryParameters: query));

  @override
  Future<Map<String, dynamic>> post(String path, {Object? body}) => _run(() => _dio.post(path, data: body));

  @override
  Future<Map<String, dynamic>> patch(String path, {Object? body}) => _run(() => _dio.patch(path, data: body));

  @override
  Future<void> delete(String path) => _run(() => _dio.delete(path));

  /// Surfaces [ApiException] directly instead of wrapped in DioException.
  Future<Map<String, dynamic>> _run(Future<Response> Function() call) async {
    try {
      final r = await call();
      return (r.data as Map?)?.cast<String, dynamic>() ?? const {};
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error! : ApiException('network', 'Check your connection and try again.');
    }
  }
}

/// Unwraps any thrown value into user-facing copy.
String messageOf(Object error, {String fallback = 'Something went wrong. Try again.'}) =>
    error is ApiException ? error.message : fallback;
