import 'package:local_basket/data/model/restaurants/getNearbyRestaurants/getNearByrestarants_model.dart';

abstract class GetNearbyRestaurantsState {}

class GetNearbyRestaurantsInitial extends GetNearbyRestaurantsState {}

class GetNearbyRestaurantsLoading extends GetNearbyRestaurantsState {}

class GetNearbyRestaurantsLoaded extends GetNearbyRestaurantsState {
  final GetNearByStoresModel model;

  GetNearbyRestaurantsLoaded(this.model);
}

class GetNearbyRestaurantsError extends GetNearbyRestaurantsState {
  final String message;

  GetNearbyRestaurantsError(this.message);
}
