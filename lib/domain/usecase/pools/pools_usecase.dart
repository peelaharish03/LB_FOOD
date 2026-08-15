import 'package:local_basket/data/model/pools/pools_model.dart';
import 'package:local_basket/domain/repository/pools/pools_repository.dart';

class GetPoolsUseCase {
  final PoolsRepository repository;

  GetPoolsUseCase({required this.repository});

  Future<PoolsModel> call() async {
    return await repository.getPools();
  }
}
