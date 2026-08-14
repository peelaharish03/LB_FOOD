import 'package:local_basket/data/model/address/state/state_model.dart';

abstract class GetStatesRepository {
  Future<List<StateModel>> getStates();
}
