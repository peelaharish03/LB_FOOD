import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/data/model/payment/deliveryModes/delivery_modes_model.dart';

abstract class DeliveryModesRemoteDataSource {
  Future<DeliveryModesModel> getDeliveryModes();
}

class DeliveryModesRemoteDataSourceImpl implements DeliveryModesRemoteDataSource {
  final Dio client;

  DeliveryModesRemoteDataSourceImpl({required this.client});

  @override
  Future<DeliveryModesModel> getDeliveryModes() async {
    final url = '$baseUrl$deliveryModesUrl';
    try {
      log('[DeliveryModesRemoteDataSource] GET $url');
      final response = await client.get(url);
      log(
        '[DeliveryModesRemoteDataSource] response status=${response.statusCode} '
        'data=${response.data}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return DeliveryModesModel.fromJson(response.data);
      } else {
        throw UnknownBackendException(
          "Unable to load delivery modes right now. Please try again after some time.",
        );
      }
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownBackendException(
        "Unable to load delivery modes right now. Please try again after some time.",
      );
    }
  }
}
