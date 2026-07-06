import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/address/saveAddress/saveAddress_model.dart';

abstract class SaveAddressRemoteDataSource {
  Future<SaveAddressModel> saveAddress(Map<String, dynamic> payload);
}

class SaveAddressRemoteDataSourceImpl implements SaveAddressRemoteDataSource {
  final Dio client;

  SaveAddressRemoteDataSourceImpl({required this.client});

  @override
  Future<SaveAddressModel> saveAddress(Map<String, dynamic> payload) async {
    try {
      final response = await client.post(
        '$baseUrl$saveAddressUrl',
        data: payload,
      );
print('$baseUrl$saveAddressUrl');
      print('SaveAddress Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SaveAddressModel.fromJson(response.data);
      } else {
        throw Exception(
            'Failed to save address. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('SaveAddress Error: $e');
      throw Exception('SaveAddress failed: ${e.toString()}');
    }
  }
}
