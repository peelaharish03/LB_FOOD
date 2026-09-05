import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/address/updateAddress/updateAddress_model.dart';

abstract class UpdateAddressRemoteDataSource {
  Future<UpdateAddressModel> updateAddress(
    String addressId,
    Map<String, dynamic> payload,
  );
}

class UpdateAddressRemoteDataSourceImpl implements UpdateAddressRemoteDataSource {
  final Dio client;

  UpdateAddressRemoteDataSourceImpl({required this.client});

  @override
  Future<UpdateAddressModel> updateAddress(
    String addressId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final url = '$baseUrl$updateAddressUrl/$addressId';
      print('UpdateAddress PUT $url payload=$payload');

      final response = await client.put(url, data: payload);

      print('UpdateAddress Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return UpdateAddressModel.fromJson(response.data);
      } else {
        throw UnknownBackendException(
          "Unable to complete this request. Please try again after some time.",
        );
      }
    } on DioException catch (e) {
      throw handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownBackendException(
        "Unable to complete this request. Please try again after some time.",
      );
    }
  }
}
