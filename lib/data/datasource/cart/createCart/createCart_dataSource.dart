import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/cart/createCart/createCart_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class CreateCartRemoteDataSource {
  Future<CreateCartModel> createCart();
}

class CreateCartRemoteDataSourceImpl implements CreateCartRemoteDataSource {
  final Dio client;

  CreateCartRemoteDataSourceImpl({required this.client});

  @override
  Future<CreateCartModel> createCart() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('device_id') ?? '';
    try {
      final response = await client.post(
        '$baseUrl$createCartUrl',
        options: Options(
          headers: {
            'X-Device-Id': deviceId,
          },
        ),
      );

      print('CreateCart Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CreateCartModel.fromJson(response.data);
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
