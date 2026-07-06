import 'package:local_basket/data/datasource/restaurants/getNearbyRestaurants/getNearByrestarants_dataSource.dart';
import 'package:local_basket/data/model/restaurants/getNearbyRestaurants/getNearByrestarants_model.dart';
import 'package:local_basket/domain/repository/restaurants/getNearbyRestaurants/getNearByrestarants_repository.dart';

class GetNearByRestaurantsRepositoryImpl implements GetNearByRestaurantsRepository {
  final GetNearByRestaurantsRemoteDataSource remoteDataSource;

  GetNearByRestaurantsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<GetNearByStoresModel> getNearByRestaurants(Map<String, dynamic> params) {
    return remoteDataSource.getNearByRestaurants(params);
  }
}
