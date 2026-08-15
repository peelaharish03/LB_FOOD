import 'package:local_basket/data/model/pools/joinPool/joinPool_model.dart';

abstract class JoinPoolRepository {
  Future<JoinPoolModel> joinPool(String poolId);
}
