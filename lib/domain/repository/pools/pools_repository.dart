import 'package:local_basket/data/model/pools/pools_model.dart';

abstract class PoolsRepository {
  Future<PoolsModel> getPools();
}
