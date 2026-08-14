import 'package:local_basket/data/model/address/state/state_model.dart';
import 'package:local_basket/domain/repository/address/state/state_repository.dart';

class GetStatesUseCase {
  final GetStatesRepository repository;

  GetStatesUseCase({required this.repository});

  Future<List<StateModel>> call() {
    return repository.getStates();
  }
}
