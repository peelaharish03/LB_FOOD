import 'package:local_basket/data/datasource/cart/productsAddToCart/productsAddtoCart_dataSource.dart';
import 'package:local_basket/data/model/cart/productsAddToCart/productsAddtoCart_model.dart';
import 'package:local_basket/domain/repository/cart/productsAddToCart/productsAddtoCart_repository.dart';

class ProductsAddToCartRepositoryImpl implements ProductsAddToCartRepository {
  final ProductsAddToCartRemoteDataSource remoteDataSource;

  ProductsAddToCartRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ProductsAddToCartModel> productsAddToCart(
    cartId,
    Map<String, dynamic> payload, {
    bool forceReplace = false,
  }) {
    return remoteDataSource.productsAddToCart(cartId, payload);
  }
}
