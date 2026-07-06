import 'package:local_basket/data/model/restaurants/getNearbyRestaurants/getNearByrestarants_model.dart';
import 'package:local_basket/domain/repository/restaurants/getNearbyRestaurants/getNearByrestarants_repository.dart';

class GetNearByRestaurantsUseCase {
  final GetNearByRestaurantsRepository repository;

  GetNearByRestaurantsUseCase({required this.repository});

  Future<GetNearByStoresModel> call(Map<String, dynamic> params) {
    return repository.getNearByRestaurants(params);
  }
}
