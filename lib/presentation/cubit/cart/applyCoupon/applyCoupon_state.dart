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

  ApplyCouponFailure(this.error);
}
