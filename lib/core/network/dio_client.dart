import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';

// NOTE: SharedPreferences import removed.
// TOKEN and REFRESH_TOKEN are now read/written via FlutterSecureStorage.
// ACTION REQUIRED: Wherever you write 'TOKEN' or 'REFRESH_TOKEN' during login/signup
// (e.g. in your signin_remote_data_source or sigin_cubit), replace
// prefs.setString('TOKEN', value) with:
//   final storage = FlutterSecureStorage();
//   await storage.write(key: 'TOKEN', value: value);
// Do the same for REFRESH_TOKEN, and update SplashScreen's token read too.

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

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final requiresAuth = options.extra['requiresAuth'] != false;

          if (requiresAuth) {
            // FIX: Read token from secure storage (encrypted) instead of SharedPreferences (plaintext)
            final token = await secureStorage.read(key: 'TOKEN');

            if (token != null && token.isNotEmpty) {
              options.headers["Authorization"] = "Bearer $token";
            } else {
              options.headers.remove("Authorization");
            }
          } else {
            options.headers.remove("Authorization");
          }

          log(
            'REQUEST[${options.method}] => PATH: ${options.path} '
            '=> Request Values: ${options.queryParameters}',
          );
          return handler.next(options);
        },
        onResponse: (response, handler) {
          log('RESPONSE[${response.statusCode}] => DATA: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          final statusCode = error.response?.statusCode;
          final data = error.response?.data;
          String errorMessage = 'Unknown error occurred';
          if (data is Map && data['message'] != null) {
            errorMessage = data['message'].toString();
          } else if (data is String) {
            errorMessage = data;
          } else if (data != null) {
            errorMessage = data.toString();
          }

          log(
            'ERROR[$statusCode] => PATH: ${error.requestOptions.uri} '
            '=> TYPE: ${error.type} => MESSAGE: $errorMessage '
            '=> ERROR: ${error.error}',
          );

          // Prevent infinite loop if refresh token request itself fails
          final isRefreshingToken = error.requestOptions.path.contains(
            'auth/refreshToken',
          );

          if (statusCode == 401 &&
              !isRefreshingToken &&
              error.requestOptions.extra['requiresAuth'] != false) {
            // FIX: Read refresh token from secure storage
            final refreshToken = await secureStorage.read(key: 'REFRESH_TOKEN');

            if (refreshToken != null) {
              try {
                final refreshResponse = await dio.post(
                  '$baseUrl2/auth/refreshToken',
                  options: Options(extra: {'requiresAuth': false}),
                  data: {'refreshToken': refreshToken},
                );

                final newToken = refreshResponse.data['accessToken'];
                final newRefreshToken = refreshResponse.data['refreshToken'];

                // FIX: Write refreshed tokens to secure storage
                await secureStorage.write(key: 'TOKEN', value: newToken);
                await secureStorage.write(
                  key: 'REFRESH_TOKEN',
                  value: newRefreshToken,
                );

                final RequestOptions requestOptions = error.requestOptions;
                requestOptions.headers["Authorization"] = "Bearer $newToken";

                final response = await dio.fetch(requestOptions);
                return handler.resolve(response);
              } catch (e) {
                log('Token refresh failed: $e');
                // FIX: Clear tokens from secure storage on refresh failure
                await secureStorage.delete(key: 'TOKEN');
                await secureStorage.delete(key: 'REFRESH_TOKEN');
                return handler.reject(error);
              }
            }
          }

          return handler.next(error);
        },
      ),
    );
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
