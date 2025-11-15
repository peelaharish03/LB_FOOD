import 'package:local_basket/data/model/payment/payment_model.dart';

abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentTrackingInitial extends PaymentState {}

class PaymentRefundInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentTrackingLoading extends PaymentState {}

class PaymentRefundLoading extends PaymentState {}

class PaymentSuccess extends PaymentState {
  final PaymentModel paymentModel;

  PaymentSuccess(this.paymentModel);
}

class PaymentTrackingSuccess extends PaymentState {
  final PaymentStausModel paymenStatustModel;

  PaymentTrackingSuccess(this.paymenStatustModel);
}

class PaymentRefundSuccess extends PaymentState {
  final PaymentRefundModel paymentRefundModel;
  PaymentRefundSuccess(this.paymentRefundModel);
}

class PaymentFailure extends PaymentState {
  final String error;
  PaymentFailure(this.error);
}

class PaymentTrackingFailure extends PaymentState {
  final String error;
  PaymentTrackingFailure(this.error);
}

class PaymentRefundFailure extends PaymentState {
  final String error;
  PaymentRefundFailure(this.error);
}
