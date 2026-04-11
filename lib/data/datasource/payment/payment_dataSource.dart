import 'package:dio/dio.dart';
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
    print('payload: $payload');
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('device_id') ?? '';
    try {
      final response = await client.post(
        '$baseUrl$paymentUrl',
        data: payload,
        options: Options(
          headers: {
            'X-Device-Id': deviceId,
          },
        ),
      );

      print('Payment Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PaymentModel.fromJson(response.data);
      } else {
        throw Exception(
            'Failed to save address. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Payment Error: $e');
      throw Exception('Payment failed: ${e.toString()}');
    }
  }

  @override
  Future<PaymentStausModel> Payment_Tracking(String paymentId) async {
    try {
      final response = await client.post(
        '$baseUrl$paymentRefundStatus/$paymentId',
      );

      print('Payment Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PaymentStausModel.fromJson(response.data);
      } else {
        throw Exception(
            'Failed payment tracking. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Payment Error: $e');
      throw Exception('Payment failed: ${e.toString()}');
    }
  }

  @override
  Future<PaymentRefundModel> Payment_Refund(String paymentId) async {
    try {
      final response = await client.post(
        '$baseUrl$paymentReFund/$paymentId',
      );

      print('Payment refund Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PaymentRefundModel.fromJson(response.data);
      } else {
        throw Exception(
            'Failed payment refund. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Payment Error: $e');
      throw Exception('Payment refund failed: ${e.toString()}');
    }
  }
}
