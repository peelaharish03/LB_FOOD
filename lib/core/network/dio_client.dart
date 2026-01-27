import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';

enum Method { post, get, put, delete, patch }

class DioClient {
  final Dio dio;
  final FlutterSecureStorage secureStorage;

  DioClient(this.dio, {required this.secureStorage}) {
    dio
      ..options.baseUrl = baseUrl
      ..options.connectTimeout = const Duration(seconds: 30)
      ..options.receiveTimeout = const Duration(seconds: 30)
      ..options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('TOKEN');

        options.headers["Authorization"] = "Bearer $token";
      
        log('REQUEST[${options.method}] => PATH: ${options.path} '
            '=> Request Values: ${options.queryParameters}, => HEADERS: ${options.headers}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        log('RESPONSE[${response.statusCode}] => DATA: ${response.data}');
        return handler.next(response);
      },
      onError: (DioException error, handler) async {
        final statusCode = error.response?.statusCode;
        print(statusCode);
        final data = error.response?.data;
        String errorMessage = 'Unknown error occurred';
        if (data is Map && data['message'] != null) {
          errorMessage = data['message'].toString();
        } else if (data is String) {
          errorMessage = data;
        } else if (data != null) {
          errorMessage = data.toString();
        }

        log('ERROR[$statusCode] => MESSAGE: $errorMessage');

        final prefs = await SharedPreferences.getInstance();

        // Prevent infinite loop if refresh token request itself fails
        final isRefreshingToken =
            error.requestOptions.path.contains('auth/refreshToken');

        if (statusCode == 401 && !isRefreshingToken) {
          final refreshToken = prefs.getString('REFRESH_TOKEN');

          if (refreshToken != null) {
            try {
              final refreshResponse = await dio.post(
                '${baseUrl2}auth/refreshToken',
                data: {
                  'refreshToken': refreshToken,
                },
              );

              final newToken = refreshResponse.data['token'];
              final newRefreshToken = refreshResponse.data['refreshToken'];

              await prefs.setString('TOKEN', newToken);
              await prefs.setString('REFRESH_TOKEN', newRefreshToken);

              final RequestOptions requestOptions = error.requestOptions;
              requestOptions.headers["Authorization"] = "Bearer $newToken";

              final response = await dio.fetch(requestOptions);
              return handler.resolve(response);
            } catch (e) {
              log('Token refresh failed: $e');
              await prefs.remove('TOKEN');
              await prefs.remove('REFRESH_TOKEN');
              return handler.reject(error);
            }
          }
        }

        return handler.next(error);
      },
    ));
  }

  Future<Response> request(
    String path, {
    Method method = Method.get,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    String? customBaseUrl,
  }) async {
    final Options options = Options(method: method.name.toUpperCase());
    final String url = (customBaseUrl ?? dio.options.baseUrl) + path;

    try {
      final response = await dio.request(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException {
      rethrow;
    }
  }
}
