import 'package:local_basket/data/datasource/pools/joinPool/joinPool_dataSource.dart';
import 'package:local_basket/data/model/pools/joinPool/joinPool_model.dart';
import 'package:local_basket/domain/repository/pools/joinPool/joinPool_repository.dart';

class JoinPoolRepositoryImpl implements JoinPoolRepository {
  final JoinPoolRemoteDataSource remoteDataSource;

  JoinPoolRepositoryImpl({required this.remoteDataSource});

  @override
  Future<JoinPoolModel> joinPool(String poolId) async {
    return await remoteDataSource.joinPool(poolId);
  }
}
