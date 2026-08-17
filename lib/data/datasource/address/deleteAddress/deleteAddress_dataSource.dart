import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/address/deleteAddress/deleteAddress_model.dart';

abstract class DeleteAddressRemoteDataSource {
  Future<DeleteAddressModel> DeleteAddress(String addressId);
}

class DeleteAddressRemoteDataSourceImpl
    implements DeleteAddressRemoteDataSource {
  final Dio client;

  DeleteAddressRemoteDataSourceImpl({required this.client});

  @override
  Future<DeleteAddressModel> DeleteAddress(String addressId) async {
    try {
      final response = await client.delete(
        '$baseUrl$deleteAddressUrl/$addressId',
      );

      print('DeleteAddress Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return DeleteAddressModel.fromJson(response.data);
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
