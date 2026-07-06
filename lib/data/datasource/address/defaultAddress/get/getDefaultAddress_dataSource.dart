import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/address/defaultAddress/get/getDefaultAddress_model.dart';

abstract class AddressSavetoCartRemoteDataSource {
  Future<AddressSavetoCartModel> addressSavetoCart(String addressId);
}

class AddressSavetoCartRemoteDataSourceImpl
    implements AddressSavetoCartRemoteDataSource {
  final Dio client;

  AddressSavetoCartRemoteDataSourceImpl({required this.client});

  @override
  Future<AddressSavetoCartModel> addressSavetoCart(String addressId) async {
    try {
      final response = await client.post(
        '$baseUrl${'$addressSavetoCartUrl=$addressId'}',
      );

      print('AddressSavetoCart Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AddressSavetoCartModel.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to create cart. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('AddressSavetoCart Error: $e');
      throw Exception('AddressSavetoCart failed: ${e.toString()}');
    }
  }
}
