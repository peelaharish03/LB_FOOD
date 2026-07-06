import 'package:local_basket/data/model/cart/productsAddToCart/productsAddtoCart_model.dart';

abstract class ProductsAddToCartRepository {
  Future<ProductsAddToCartModel> productsAddToCart(
    cartId,
    Map<String, dynamic> payload, {
    bool forceReplace = false,
  });
}
