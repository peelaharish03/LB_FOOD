import 'package:local_basket/data/model/cart/eligiblePromotions/eligiblePromotions_model.dart';

abstract class EligiblePromotionsState {}

class EligiblePromotionsInitial extends EligiblePromotionsState {}

class EligiblePromotionsLoading extends EligiblePromotionsState {}

class EligiblePromotionsLoaded extends EligiblePromotionsState {
  final EligiblePromotionsModel model;
  EligiblePromotionsLoaded({required this.model});
}

class EligiblePromotionsFailure extends EligiblePromotionsState {
  final String error;
  EligiblePromotionsFailure({required this.error});
}
