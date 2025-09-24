import 'package:local_basket/data/model/offers/restaurant_offers/restaurant_offers_model.dart';

abstract class RestaurantOffersState {}

class RestaurantOffersInitial extends RestaurantOffersState {}

class RestaurantOffersLoading extends RestaurantOffersState {}

class RestaurantOffersLoaded extends RestaurantOffersState {
  final RestaurantOffersModel offers;
  RestaurantOffersLoaded({required this.offers});
}

class RestaurantOffersError extends RestaurantOffersState {
  final String message;
  RestaurantOffersError({required this.message});
}
