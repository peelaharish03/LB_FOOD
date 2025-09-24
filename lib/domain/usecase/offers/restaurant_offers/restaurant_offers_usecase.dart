import 'package:local_basket/data/model/offers/restaurant_offers/restaurant_offers_model.dart';
import 'package:local_basket/domain/repository/offers/restaurant_offers/restaurant_offers_repository.dart';

class RestaurantOffersUseCase {
  final RestaurantOffersRepository repository;

  RestaurantOffersUseCase({required this.repository});

  Future<RestaurantOffersModel> call() async {
    return await repository.getRestaurantOffers();
  }
}
