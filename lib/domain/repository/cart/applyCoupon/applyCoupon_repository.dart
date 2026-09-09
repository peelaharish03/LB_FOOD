abstract class ApplyCouponRepository {
  Future<void> applyCoupon(String cartId, String code);
  Future<void> removeCoupon(String cartId, String code);
}
