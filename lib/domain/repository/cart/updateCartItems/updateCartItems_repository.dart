import 'package:local_basket/data/model/cart/updateCartItems/updateCartItems_model.dart';

abstract class UpdateCartItemsRepository {
  Future<UpdateCartItemsModel> updateCartItems(
    Map<String, dynamic> payload,
    String cartId,
    String itemId,
  );
}
