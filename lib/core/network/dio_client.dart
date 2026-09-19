import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';
import '../constants/app_navigator.dart';
import '../../presentation/screen/authentication/login_screen.dart';

enum Method { post, get, put, delete, patch }

/// Some gateway/backend responses come back with a JSON content-type but a
/// body that isn't valid JSON (e.g. a plain-text error page or an empty
/// success body). Left alone, `jsonDecode` throws a FormatException that
/// Dio surfaces as `DioExceptionType.unknown` with no attached response —
/// which then gets misreported to the user as "No internet connection"
/// even though the request actually reached the server. Decoding it this
/// way keeps the request from crashing outright so `response.statusCode`
/// stays available to the caller.
dynamic _safeJsonDecode(String text) {
  try {
    return jsonDecode(text);
  } on FormatException catch (e) {
    log(
      'Non-JSON response body (${text.length} chars): '
      '${text.length > 300 ? text.substring(0, 300) : text}\n$e',
    );
    return <String, dynamic>{'_rawResponse': text};
  }
}

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
      }
      ..transformer = (BackgroundTransformer()
        ..jsonDecodeCallback = _safeJsonDecode);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final requiresAuth = options.extra['requiresAuth'] != false;

          if (requiresAuth) {
            // FIX: Read token from secure storage (encrypted) instead of SharedPreferences (plaintext)
            final token = await secureStorage.read(key: 'TOKEN');
            log('ACCESS TOKEN[${options.path}] => $token');

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
            'auth/refresh',
          );

          // Some endpoints (e.g. checkout) return a plain 401 for a
          // business-state conflict — "Cart is not active:
          // CHECKOUT_IN_PROGRESS" — rather than an expired token. Without
          // this flag, retrying such a request after a token refresh keeps
          // 401ing, which re-enters this handler and refreshes/retries
          // forever. Capping it to a single retry per request breaks that
          // loop regardless of why the 401 keeps happening.
          final alreadyRetried =
              error.requestOptions.extra['_retriedAfter401'] == true;

          if (statusCode == 401 &&
              !isRefreshingToken &&
              !alreadyRetried &&
              error.requestOptions.extra['requiresAuth'] != false) {
            final String newToken;
            try {
              // Shares one in-flight refresh across all requests that 401
              // at the same time, instead of each racing to rotate the
              // refresh token independently.
              newToken = await _refreshAccessToken();
            } catch (e) {
              log('Token refresh failed: $e');
              await _signOutAndReturnToLogin();
              return handler.reject(error);
            }

            try {
              final RequestOptions requestOptions = error.requestOptions;
              requestOptions.headers["Authorization"] = "Bearer $newToken";
              requestOptions.extra = {
                ...requestOptions.extra,
                '_retriedAfter401': true,
              };

              final response = await dio.fetch(requestOptions);
              return handler.resolve(response);
            } on DioException catch (retryError) {
              // The refresh succeeded — the token wasn't the problem — so
              // this is the request's own error (e.g. that cart-state
              // conflict). Surface it as-is instead of signing the user out.
              return handler.next(retryError);
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  // In-flight refresh call, shared by every request that 401s while a
  // refresh is already underway. Without this, N concurrent 401s would
  // each POST /auth/refreshToken with the same (soon-to-be-rotated) old
  // refresh token, and every rotation but the first would be rejected by
  // the backend or clobber the token secure storage just wrote.
  Future<String>? _refreshFuture;

  Future<String> _refreshAccessToken() {
    return _refreshFuture ??= _doRefreshAccessToken().whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<String> _doRefreshAccessToken() async {
    final refreshToken = await secureStorage.read(key: 'REFRESH_TOKEN');
    if (refreshToken == null || refreshToken.isEmpty) {
      // No refresh token on hand either — the session is simply gone.
      throw StateError('No refresh token available');
    }

    // Must be the SAME deviceId that was sent at login — the backend binds
    // the refresh token to that device and rejects a mismatch. Login
    // currently sends the literal 'device-uuid-123' (see SignInCubit.signIn),
    // NOT the real per-device id stored in prefs under 'device_id', so we
    // must use the same literal here.
    const deviceId = 'device-uuid-123';

    final refreshResponse = await dio.post(
      '$baseUrl/auth/refresh',
      options: Options(extra: {'requiresAuth': false}),
      data: {'refreshToken': refreshToken, 'deviceId': deviceId},
    );

    final data = refreshResponse.data;
    if (data is! Map ||
        data['accessToken'] is! String ||
        data['refreshToken'] is! String) {
      throw StateError('Unexpected refresh response: $data');
    }

    final newToken = data['accessToken'] as String;
    final newRefreshToken = data['refreshToken'] as String;

    await secureStorage.write(key: 'TOKEN', value: newToken);
    await secureStorage.write(key: 'REFRESH_TOKEN', value: newRefreshToken);

    return newToken;
  }

  bool _redirectingToLogin = false;

  /// Clears the stored session and drops the user back at the login
  /// screen, so an expired/invalid session shows a fresh login screen
  /// instead of leaving the user stuck on a broken authenticated screen.
  Future<void> _signOutAndReturnToLogin() async {
    await secureStorage.delete(key: 'TOKEN');
    await secureStorage.delete(key: 'REFRESH_TOKEN');

    if (_redirectingToLogin) return;
    final navigator = AppNavigator.key.currentState;
    if (navigator == null) return;

    _redirectingToLogin = true;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    _redirectingToLogin = false;
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
