import 'package:local_basket/domain/repository/cart/applyCoupon/applyCoupon_repository.dart';

class ApplyCouponUseCase {
  final ApplyCouponRepository repository;

  ApplyCouponUseCase({required this.repository});

  Future<void> apply(String cartId, String code) {
    return repository.applyCoupon(cartId, code);
  }

  Future<void> remove(String cartId, String code) {
    return repository.removeCoupon(cartId, code);
  }
}
