import 'package:local_basket/data/datasource/address/state/state_dataSource.dart';
import 'package:local_basket/data/model/address/state/state_model.dart';
import 'package:local_basket/domain/repository/address/state/state_repository.dart';

class GetStatesRepositoryImpl implements GetStatesRepository {
  final GetStatesRemoteDataSource remoteDataSource;

  GetStatesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<StateModel>> getStates() {
    return remoteDataSource.getStates();
  }
}
