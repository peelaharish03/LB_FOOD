import 'package:local_basket/data/model/cart/clearCart/clearCart_model.dart';

abstract class ClearCartRepository {
  Future<ClearCartModel> clearCart(String cartId);
}
