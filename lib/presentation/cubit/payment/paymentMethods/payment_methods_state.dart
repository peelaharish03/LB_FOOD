import 'package:local_basket/data/model/payment/paymentMethods/payment_methods_model.dart';

abstract class PaymentMethodsState {}

class PaymentMethodsInitial extends PaymentMethodsState {}

class PaymentMethodsLoading extends PaymentMethodsState {}

class PaymentMethodsLoaded extends PaymentMethodsState {
  final PaymentMethodsModel model;
  PaymentMethodsLoaded({required this.model});
}

class PaymentMethodsFailure extends PaymentMethodsState {
  final String error;
  PaymentMethodsFailure({required this.error});
}
