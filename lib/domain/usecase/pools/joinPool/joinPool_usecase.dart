import 'package:local_basket/data/model/pools/joinPool/joinPool_model.dart';
import 'package:local_basket/domain/repository/pools/joinPool/joinPool_repository.dart';

class JoinPoolUseCase {
  final JoinPoolRepository repository;

  JoinPoolUseCase({required this.repository});

  Future<JoinPoolModel> call(String poolId) async {
    return await repository.joinPool(poolId);
  }
}
