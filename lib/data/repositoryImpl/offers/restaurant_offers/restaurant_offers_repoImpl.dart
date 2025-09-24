import 'package:local_basket/data/datasource/offers/restaurant_offers/restaurant_offers_dataSource.dart';
import 'package:local_basket/data/model/offers/restaurant_offers/restaurant_offers_model.dart';
import 'package:local_basket/domain/repository/offers/restaurant_offers/restaurant_offers_repository.dart';

class RestaurantOffersRepositoryImpl implements RestaurantOffersRepository {
  final RestaurantOffersRemoteDataSource remoteDataSource;

  RestaurantOffersRepositoryImpl({required this.remoteDataSource});

  @override
  Future<RestaurantOffersModel> getRestaurantOffers() async {
    return await remoteDataSource.restaurantOffers();
  }
}
