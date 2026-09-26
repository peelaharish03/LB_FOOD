import 'package:local_basket/data/model/payment/checkout_model.dart';

abstract class CheckoutState {}

class CheckoutInitial extends CheckoutState {}

class CheckoutLoading extends CheckoutState {}

class CheckoutSuccess extends CheckoutState {
  final CheckoutModel model;
  CheckoutSuccess({required this.model});
}

class CheckoutFailure extends CheckoutState {
  final String error;

  /// True when the failed call was a background refresh (the charges
  /// preview) — the screen shouldn't pop an error the buyer didn't cause.
  final bool silent;
  CheckoutFailure({required this.error, this.silent = false});
}
