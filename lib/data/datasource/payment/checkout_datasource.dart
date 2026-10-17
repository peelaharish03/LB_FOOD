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

  /// Releases a cart held by an abandoned/failed online-payment checkout,
  /// restoring it to the items it had before checkout was triggered. Must
  /// only be called when the payment did NOT succeed.
  Future<CheckoutModel> cancelCheckout(String cartId);
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
      final storeInactive = _storeInactiveError(e);
      if (storeInactive != null) throw storeInactive;
      final mapped = handleDioError(e);
      // Checkout endpoints reply 401 / auth-style codes for business-state
      // problems too (cart or store not active). A genuinely expired session
      // was already handled by the Dio interceptor (refresh or sign-out), so
      // don't tell the buyer to log in again — show the backend's reason.
      if (mapped is UnauthorizedException) {
        throw UnknownBackendException(
          _backendMessage(e) ??
              "Unable to complete checkout right now. Please try again after some time.",
          mapped.code,
        );
      }
      throw mapped;
    } catch (e) {
      log('[CheckoutRemoteDataSource:$tag] error=$e');
      if (e is AppException) rethrow;
      throw UnknownBackendException(
        "Unable to complete checkout right now. Please try again after some time.",
      );
    }
  }

  static String? _backendMessage(DioException e) {
    final data = e.response?.data;
    final message =
        data is Map ? data['message']?.toString() : (data is String ? data : null);
    final trimmed = message?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static final RegExp _storeInactivePattern = RegExp(
    r'(store|restaurant|outlet|shop).*(inactive|not active|closed|unavailable|offline|disabled)'
    r'|(inactive|closed|unavailable|offline|disabled).*(store|restaurant|outlet|shop)',
    caseSensitive: false,
  );

  /// Detects the backend's "store is inactive/closed" rejection, whatever
  /// HTTP status or business code it arrives with.
  static StoreInactiveException? _storeInactiveError(DioException e) {
    final message = _backendMessage(e);
    if (message == null || !_storeInactivePattern.hasMatch(message)) {
      return null;
    }
    final data = e.response?.data;
    final code = data is Map ? data['code'] : null;
    return StoreInactiveException(
      "This store / restaurant is currently inactive. Please try again after some time.",
      code is int ? code : e.response?.statusCode,
    );
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

  @override
  Future<CheckoutModel> cancelCheckout(String cartId) {
    return _post('cancel', '$baseUrl${checkoutCancelUrl(cartId)}', const {});
  }
}
