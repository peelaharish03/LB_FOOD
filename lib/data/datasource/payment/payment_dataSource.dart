import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/payment/payment_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class PaymentRemoteDataSource {
  Future<PaymentModel> Payment(Map<String, dynamic> payload);
  Future<PaymentStausModel> Payment_Tracking(String paymentId);
  Future<PaymentRefundModel> Payment_Refund(String paymentId);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final Dio client;

  PaymentRemoteDataSourceImpl({required this.client});

  @override
  Future<PaymentModel> Payment(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('device_id') ?? '';
    final url = '$baseUrl$paymentUrl';
    log(
      '[PaymentRemoteDataSource] POST $url '
      'orderId=${payload['orderId']} cartId=${payload['cartId']} '
      'amount=${payload['amount']} paymentId=${payload['paymentId']} '
      'razorpayOrderId=${payload['razorpayOrderId']} '
      'signaturePresent=${payload['razorpaySignature'] != null} '
      'deviceIdPresent=${deviceId.isNotEmpty}',
    );
    try {
      final response = await client.post(
        url,
        data: payload,
        options: Options(headers: {'X-Device-Id': deviceId}),
      );

      log(
        '[PaymentRemoteDataSource] response status=${response.statusCode} '
        'data=${response.data}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PaymentModel.fromJson(response.data);
      } else {
        throw UnknownBackendException("Unable to complete this request. Please try again after some time.");
      }
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownBackendException("Unable to complete this request. Please try again after some time.");
    }
  }

  @override
  Future<PaymentStausModel> Payment_Tracking(String paymentId) async {
    final url = '$baseUrl$paymentRefundStatus/$paymentId';
    try {
      log('[PaymentRemoteDataSource] tracking POST $url');
      final response = await client.post(url);

      log(
        '[PaymentRemoteDataSource] tracking response '
        'status=${response.statusCode} data=${response.data}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PaymentStausModel.fromJson(response.data);
      } else {
        throw UnknownBackendException("Unable to complete this request. Please try again after some time.");
      }
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownBackendException("Unable to complete this request. Please try again after some time.");
    }
  }

  @override
  Future<PaymentRefundModel> Payment_Refund(String paymentId) async {
    final url = '$baseUrl$paymentReFund/$paymentId';
    try {
      log('[PaymentRemoteDataSource] refund POST $url');
      final response = await client.post(url);

      log(
        '[PaymentRemoteDataSource] refund response '
        'status=${response.statusCode} data=${response.data}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PaymentRefundModel.fromJson(response.data);
      } else {
        throw UnknownBackendException("Unable to complete this request. Please try again after some time.");
      }
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownBackendException("Unable to complete this request. Please try again after some time.");
    }
  }
}
