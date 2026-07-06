import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/cart/productsAddToCart/productsAddtoCart_model.dart';

abstract class ProductsAddToCartRemoteDataSource {
  Future<ProductsAddToCartModel> productsAddToCart(
    cartId,
    Map<String, dynamic> payload,
  );
}

class ProductsAddToCartRemoteDataSourceImpl
    implements ProductsAddToCartRemoteDataSource {
  final Dio client;

  ProductsAddToCartRemoteDataSourceImpl({required this.client});

  @override
  Future<ProductsAddToCartModel> productsAddToCart(
    cartId,
    Map<String, dynamic> payload,
  ) async {
    print('ProductsAddToCart Payload: $payload');
    try {
      final response = await client.post(
        '$baseUrl$productsAddToCartUrl/$cartId/items',
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      print('ProductsAddToCart Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ProductsAddToCartModel.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to ProductsAddToCart. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('ProductsAddToCart Error: $e');
      throw Exception('ProductsAddToCart failed: ${e.toString()}');
    }
  }
}
