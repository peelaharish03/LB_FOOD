abstract class ApplyCouponState {}

class ApplyCouponInitial extends ApplyCouponState {}

class ApplyCouponLoading extends ApplyCouponState {
  /// The code being applied, or null while a code is being removed.
  final String? code;

  ApplyCouponLoading({this.code});
}

class ApplyCouponSuccess extends ApplyCouponState {
  /// The applied code, or null when the coupon was removed.
  final String? code;

  ApplyCouponSuccess({this.code});
}

class ApplyCouponFailure extends ApplyCouponState {
  final String error;

  /// True when the failed call was a background clean-up (dropping the old
  /// promo when the payment method changes) — no error popup for it.
  final bool silent;

  ApplyCouponFailure(this.error, {this.silent = false});
}
