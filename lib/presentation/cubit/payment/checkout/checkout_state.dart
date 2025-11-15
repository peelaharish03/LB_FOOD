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
  CheckoutFailure({required this.error});
}
