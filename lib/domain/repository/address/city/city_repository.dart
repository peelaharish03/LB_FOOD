import 'package:local_basket/data/model/address/state/state_model.dart';

abstract class GetCitiesRepository {
  Future<List<CityModel>> getCities([String? stateCode]);
}
