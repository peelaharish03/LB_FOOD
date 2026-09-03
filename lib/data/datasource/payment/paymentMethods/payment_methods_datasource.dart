import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/data/model/payment/paymentMethods/payment_methods_model.dart';

abstract class PaymentMethodsRemoteDataSource {
  Future<PaymentMethodsModel> getPaymentMethods();
}

class PaymentMethodsRemoteDataSourceImpl
    implements PaymentMethodsRemoteDataSource {
  final Dio client;

  PaymentMethodsRemoteDataSourceImpl({required this.client});

  @override
  Future<PaymentMethodsModel> getPaymentMethods() async {
    final url = '$baseUrl$paymentMethodsUrl';
    try {
      log('[PaymentMethodsRemoteDataSource] GET $url');
      final response = await client.get(url);
      log(
        '[PaymentMethodsRemoteDataSource] response status=${response.statusCode} '
        'data=${response.data}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PaymentMethodsModel.fromJson(response.data);
      } else {
        throw UnknownBackendException(
          "Unable to load payment methods right now. Please try again after some time.",
        );
      }
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownBackendException(
        "Unable to load payment methods right now. Please try again after some time.",
      );
    }
  }
}
