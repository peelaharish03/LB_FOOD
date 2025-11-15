import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/payment/checkout_model.dart';

abstract class CheckoutRemoteDataSource {
  Future<CheckoutModel> checkout();
}

class CheckoutRemoteDataSourceImpl implements CheckoutRemoteDataSource {
  final Dio client;

  CheckoutRemoteDataSourceImpl({required this.client});

  @override
  Future<CheckoutModel> checkout() async {
    try {
      final response = await client.request(
        '$baseUrl$checkoutUrl',
        options: Options(method: 'GET'),
      );
      if (response.statusCode == 200) {
        print('responce of Checkout:: $response');
        return CheckoutModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load Checkout data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load Checkout data: ${e.toString()}');
    }
  }
}
