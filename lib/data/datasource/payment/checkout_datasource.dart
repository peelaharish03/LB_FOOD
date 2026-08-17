import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/data/model/payment/checkout_model.dart';

abstract class CheckoutRemoteDataSource {
  /// Step 1 of the online-payment flow: moves the cart into checkout.
  Future<CheckoutModel> checkout(Map<String, dynamic> payload);

  /// Step 2 of the online-payment flow: returns the Razorpay order/key to
  /// open the payment sheet with.
  Future<CheckoutModel> initiateCheckout(Map<String, dynamic> payload);

  /// Cash-on-delivery checkout: creates the order directly, no payment
  /// gateway involved.
  Future<CheckoutModel> checkoutCod(Map<String, dynamic> payload);

  /// Reports the outcome of a Razorpay payment attempt back to the backend.
  Future<CheckoutModel> verifyPayment(Map<String, dynamic> payload);
}

class CheckoutRemoteDataSourceImpl implements CheckoutRemoteDataSource {
  final Dio client;
  static const Duration _checkoutTimeout = Duration(seconds: 90);

  CheckoutRemoteDataSourceImpl({required this.client});

  Future<CheckoutModel> _post(
    String tag,
    String url,
    Map<String, dynamic> payload,
  ) async {
    try {
      log('[CheckoutRemoteDataSource:$tag] POST $url payload=$payload');
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
        '[CheckoutRemoteDataSource:$tag] response status=${response.statusCode} '
        'data=${response.data}',
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return CheckoutModel.fromJson(response.data);
      } else {
        throw UnknownBackendException(
          "Unable to complete checkout right now. Please try again after some time.",
        );
      }
    } on DioException catch (e) {
      log('[CheckoutRemoteDataSource:$tag] error=$e');
      if (e.type == DioExceptionType.receiveTimeout) {
        throw RequestTimeoutException(
          'Checkout server took too long to respond. Please try again.',
        );
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw RequestTimeoutException(
          'Checkout request timed out. Please check your internet and try again.',
        );
      }
      throw handleDioError(e);
    } catch (e) {
      log('[CheckoutRemoteDataSource:$tag] error=$e');
      if (e is AppException) rethrow;
      throw UnknownBackendException(
        "Unable to complete checkout right now. Please try again after some time.",
      );
    }
  }

  @override
  Future<CheckoutModel> checkout(Map<String, dynamic> payload) {
    return _post('checkout', '$baseUrl$checkoutUrl', payload);
  }

  @override
  Future<CheckoutModel> initiateCheckout(Map<String, dynamic> payload) {
    return _post('initiate', '$baseUrl$checkoutInitiateUrl', payload);
  }

  @override
  Future<CheckoutModel> checkoutCod(Map<String, dynamic> payload) {
    return _post('cod', '$baseUrl$checkoutCodUrl', payload);
  }

  @override
  Future<CheckoutModel> verifyPayment(Map<String, dynamic> payload) {
    return _post('verify-payment', '$baseUrl$checkoutVerifyPaymentUrl', payload);
  }
}
