import 'package:local_basket/data/model/cart/updateCartItems/updateCartItems_model.dart';
import 'package:local_basket/domain/repository/cart/updateCartItems/updateCartItems_repository.dart';

class UpdateCartItemsUseCase {
  final UpdateCartItemsRepository repository;

  UpdateCartItemsUseCase({required this.repository});

  Future<UpdateCartItemsModel> call(
    Map<String, dynamic> payload,
    String cartId,
    String itemId,
  ) {
    return repository.updateCartItems(payload, cartId, itemId);
  }
}
