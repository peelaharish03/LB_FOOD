import 'package:local_basket/data/model/offers/restaurant_offers/restaurant_offers_model.dart';

abstract class RestaurantOffersRepository {
  Future<RestaurantOffersModel> getRestaurantOffers();
}
