import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/orders/createOrder/createOrder_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class CreateOrderRemoteDataSource {
  Future<CreateOrderModel> createOrder(dynamic body);
}

class CreateOrderRemoteDataSourceImpl implements CreateOrderRemoteDataSource {
  final Dio client;

  CreateOrderRemoteDataSourceImpl({required this.client});

  @override
  Future<CreateOrderModel> createOrder(dynamic body) async {
    print("Request Body: $body");

    try {
      // ✅ Get deviceId from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_id') ?? '';

      print("DeviceId from SharedPrefs: $deviceId");

      final response = await client.post(
        '$baseUrl$createOrderUrl',
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'deviceId': deviceId, // ✅ automatically added
          },
        ),
      );

      print('CreateOrder Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CreateOrderModel.fromJson(response.data);
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
