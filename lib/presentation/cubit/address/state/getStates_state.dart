import 'package:local_basket/data/model/address/state/state_model.dart';

abstract class GetStatesState {}

class GetStatesInitial extends GetStatesState {}

class GetStatesLoading extends GetStatesState {}

class GetStatesSuccess extends GetStatesState {
  final List<StateModel> states;

  GetStatesSuccess(this.states);
}

class GetStatesFailure extends GetStatesState {
  final String error;

  GetStatesFailure(this.error);
}
