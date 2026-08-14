import 'package:local_basket/data/model/cart/clearCart/clearCart_model.dart';
import 'package:local_basket/domain/repository/cart/clearCart/clearCart_repository.dart';

class ClearCartUseCase {
  final ClearCartRepository repository;

  ClearCartUseCase({required this.repository});

  Future<ClearCartModel> call(String cartId) {
    return repository.clearCart(cartId);
  }
}
