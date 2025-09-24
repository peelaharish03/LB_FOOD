import 'package:local_basket/data/model/offers/restaurant_offers/validate_offer_model.dart';

abstract class ValidateOfferState {}

class ValidateOfferInitial extends ValidateOfferState {}

class ValidateOfferLoading extends ValidateOfferState {}

class ValidateOfferSuccess extends ValidateOfferState {
  final ValidateOfferModel validateOfferModel;
  ValidateOfferSuccess({required this.validateOfferModel});
}

class ValidateOfferFailure extends ValidateOfferState {
  final String error;
  ValidateOfferFailure({required this.error});
}
