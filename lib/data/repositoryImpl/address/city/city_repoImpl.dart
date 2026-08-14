import 'package:local_basket/data/datasource/address/city/city_dataSource.dart';
import 'package:local_basket/data/model/address/state/state_model.dart';
import 'package:local_basket/domain/repository/address/city/city_repository.dart';

class GetCitiesRepositoryImpl implements GetCitiesRepository {
  final GetCitiesRemoteDataSource remoteDataSource;

  GetCitiesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CityModel>> getCities([String? stateCode]) {
    return remoteDataSource.getCities(stateCode);
  }
}
