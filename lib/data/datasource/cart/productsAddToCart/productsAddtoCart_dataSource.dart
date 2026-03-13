import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/cart/productsAddToCart/productsAddtoCart_model.dart';

abstract class ProductsAddToCartRemoteDataSource {
  Future<List<ProductsAddToCartModel>> productsAddToCart(
    Map<String, dynamic> payload,
  );
}

class ProductsAddToCartRemoteDataSourceImpl
    implements ProductsAddToCartRemoteDataSource {
  final Dio client;

  ProductsAddToCartRemoteDataSourceImpl({required this.client});

  @override
  Future<List<ProductsAddToCartModel>> productsAddToCart(
      Map<String, dynamic> payload) async {
    payload.putIfAbsent('isOffer', () => false);
    payload.putIfAbsent('selfOrder', () => false);
    print('ProductsAddToCart Payload: $payload');
    try {
      final response = await client.post(
        '$baseUrl$productsAddToCartUrl',
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
        if (response.data is List) {
          return (response.data as List)
              .map((item) => ProductsAddToCartModel.fromJson(item))
              .toList();
        } else {
          return [ProductsAddToCartModel.fromJson(response.data)];
        }
      } else {
        throw Exception(
            'Failed to ProductsAddToCart. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('ProductsAddToCart Error: $e');
      throw Exception('ProductsAddToCart failed: ${e.toString()}');
    }
  }
}
