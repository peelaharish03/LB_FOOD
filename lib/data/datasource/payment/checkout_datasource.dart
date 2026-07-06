import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/payment/checkout_model.dart';

abstract class CheckoutRemoteDataSource {
  Future<CheckoutModel> checkout(Map<String, dynamic> payload);
}

class CheckoutRemoteDataSourceImpl implements CheckoutRemoteDataSource {
  final Dio client;

  CheckoutRemoteDataSourceImpl({required this.client});

  @override
  Future<CheckoutModel> checkout(Map<String, dynamic> payload) async {
    try {
      final response = await client.post(
        '$baseUrl$checkoutUrl',
        data: payload,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return CheckoutModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load Checkout data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load Checkout data: ${e.toString()}');
    }
  }
}
