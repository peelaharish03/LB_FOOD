import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/cart/updateCartItems/updateCartItems_model.dart';

abstract class UpdateCartItemsRemoteDataSource {
  Future<UpdateCartItemsModel> updateCartItems(
    Map<String, dynamic> payload,
    String cartId,
    String itemId,
  );
}

class UpdateCartItemsRemoteDataSourceImpl
    implements UpdateCartItemsRemoteDataSource {
  final Dio client;

  UpdateCartItemsRemoteDataSourceImpl({required this.client});

  @override
  Future<UpdateCartItemsModel> updateCartItems(
    Map<String, dynamic> payload,
    String cartId,
    String itemId,
  ) async {
    try {
      final response = await client.put(
        '$baseUrl${updateCartItemsUrl(cartId, itemId)}',
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('UpdateCartItems Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return UpdateCartItemsModel.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to UpdateCartItems. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('UpdateCartItems Error: $e');
      throw Exception('UpdateCartItems failed: ${e.toString()}');
    }
  }
}
