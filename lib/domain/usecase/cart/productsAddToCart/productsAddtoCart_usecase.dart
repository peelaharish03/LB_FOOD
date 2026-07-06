import 'package:local_basket/data/model/cart/productsAddToCart/productsAddtoCart_model.dart';
import 'package:local_basket/domain/repository/cart/productsAddToCart/productsAddtoCart_repository.dart';

class ProductsAddToCartUseCase {
  final ProductsAddToCartRepository repository;

  ProductsAddToCartUseCase(this.repository);

  Future<ProductsAddToCartModel> call(
    cartId,
    Map<String, dynamic> payload, {
    bool forceReplace = false,
  }) async {
    return await repository.productsAddToCart(
      cartId,
      payload,
      forceReplace: forceReplace,
    );
  }
}
