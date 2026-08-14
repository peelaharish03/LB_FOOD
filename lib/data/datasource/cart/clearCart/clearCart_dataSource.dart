
import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/cart/clearCart/clearCart_model.dart';

abstract class ClearCartRemoteDataSource {
  Future<ClearCartModel> clearCart(String cartId);
}

class ClearCartRemoteDataSourceImpl implements ClearCartRemoteDataSource {
  final Dio client;

  ClearCartRemoteDataSourceImpl({required this.client});

  @override
  Future<ClearCartModel> clearCart(String cartId) async {
    try {
      final response = await client.delete(
        '$baseUrl${clearCartByIdUrl(cartId)}',
      );

      print('ClearCart Response: ${response.data}');

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return ClearCartModel.fromJson(data);
        }
        return ClearCartModel(message: 'success', status: 'success', data: 1);
      } else {
        throw Exception('Failed to ClearCart. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('ClearCart Error: $e');
      throw Exception('ClearCart failed: ${e.toString()}');
    }
  }
}