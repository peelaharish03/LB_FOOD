import 'package:local_basket/data/datasource/pools/pools_datasource.dart';
import 'package:local_basket/data/model/pools/pools_model.dart';
import 'package:local_basket/domain/repository/pools/pools_repository.dart';

class PoolsRepositoryImpl implements PoolsRepository {
  final GetPoolsRemoteDataSource remoteDataSource;

  PoolsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PoolsModel> getPools() async {
    return await remoteDataSource.getPools();
  }
}
