import 'package:local_basket/data/model/address/state/state_model.dart';

abstract class GetCitiesState {}

class GetCitiesInitial extends GetCitiesState {}

class GetCitiesLoading extends GetCitiesState {}

class GetCitiesSuccess extends GetCitiesState {
  final List<CityModel> cities;
  final String? stateId;

  GetCitiesSuccess(this.cities, this.stateId);
}

class GetCitiesFailure extends GetCitiesState {
  final String error;

  GetCitiesFailure(this.error);
}
