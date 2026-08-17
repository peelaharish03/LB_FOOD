import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/address/defaultAddress/post/defaultAddress_model.dart';

abstract class DefaultAddressRemoteDataSource {
  Future<DefaultAddressModel> defaultAddress(String addressId);
}

class DefaultAddressRemoteDataSourceImpl
    implements DefaultAddressRemoteDataSource {
  final Dio client;

  DefaultAddressRemoteDataSourceImpl({required this.client});

  @override
  Future<DefaultAddressModel> defaultAddress(String addressId) async {
    try {
      final response = await client.post(
        '$baseUrl${'$defaultAddressUrl/$addressId'}',
      );

      print('DefaultAddress Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return DefaultAddressModel.fromJson(response.data);
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
