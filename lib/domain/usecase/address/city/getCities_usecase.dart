import 'package:local_basket/data/model/address/state/state_model.dart';
import 'package:local_basket/domain/repository/address/city/city_repository.dart';

class GetCitiesUseCase {
  final GetCitiesRepository repository;

  GetCitiesUseCase({required this.repository});

  Future<List<CityModel>> call([String? stateCode]) {
    return repository.getCities(stateCode);
  }
}
