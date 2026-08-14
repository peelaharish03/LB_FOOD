import 'package:local_basket/data/model/offers/promotions/promotions_model.dart';

abstract class PromotionsState {}

class PromotionsInitial extends PromotionsState {}

class PromotionsLoading extends PromotionsState {}

class PromotionsLoaded extends PromotionsState {
  final PromotionsModel promotions;
  PromotionsLoaded({required this.promotions});
}

class PromotionsError extends PromotionsState {
  final String message;
  PromotionsError({required this.message});
}
