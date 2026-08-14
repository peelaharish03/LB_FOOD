import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/payment/checkout_model.dart';

abstract class CheckoutRemoteDataSource {
  Future<CheckoutModel> checkout(Map<String, dynamic> payload);
}

class CheckoutRemoteDataSourceImpl implements CheckoutRemoteDataSource {
  final Dio client;
  static const Duration _checkoutTimeout = Duration(seconds: 90);

  CheckoutRemoteDataSourceImpl({required this.client});

  @override
  Future<CheckoutModel> checkout(Map<String, dynamic> payload) async {
    final url = '$baseUrl$checkoutUrl';
    try {
      log('[CheckoutRemoteDataSource] POST $url payload=$payload');
      final response = await client.post(
        url,
        data: payload,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: _checkoutTimeout,
          sendTimeout: _checkoutTimeout,
        ),
      );
      log(
        '[CheckoutRemoteDataSource] response status=${response.statusCode} '
        'data=${response.data}',
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return CheckoutModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load Checkout data: ${response.statusCode}');
      }
    } on DioException catch (e) {
      log('[CheckoutRemoteDataSource] error=$e');
      if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Checkout server took too long to create Razorpay order. Please try again.',
        );
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception(
          'Checkout request timed out. Please check your internet and try again.',
        );
      }
      throw Exception('Failed to load Checkout data: ${e.message}');
    } catch (e) {
      log('[CheckoutRemoteDataSource] error=$e');
      throw Exception('Failed to load Checkout data: ${e.toString()}');
    }
  }
}
