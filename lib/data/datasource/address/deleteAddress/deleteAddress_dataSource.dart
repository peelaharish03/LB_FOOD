import 'package:dio/dio.dart';
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
        throw Exception(
          'Failed to DeleteAddress. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('DeleteAddress Error: $e');
      throw Exception('DeleteAddress failed: ${e.toString()}');
    }
  }
}
