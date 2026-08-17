import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/address/getAddress/getAddress_model.dart';

abstract class GetAddressRemoteDataSource {
  Future<GetAddressModel> getAddress();
}

class GetAddressRemoteDataSourceImpl
    implements GetAddressRemoteDataSource {
  final Dio client;

  GetAddressRemoteDataSourceImpl({required this.client});

  @override
  Future<GetAddressModel> getAddress() async {
    try {
      final response = await client.request(
        '$baseUrl2$getAddressUrl',
        options: Options(method: 'GET'),
      );
      print('$baseUrl2$getAddressUrl');
      if (response.statusCode == 200) {
        print('responce of GetAddress:: $response');
        return GetAddressModel.fromJson(response.data);
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
