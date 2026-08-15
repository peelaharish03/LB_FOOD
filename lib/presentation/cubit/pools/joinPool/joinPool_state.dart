import 'package:local_basket/data/model/pools/joinPool/joinPool_model.dart';

class JoinPoolState {}

class JoinPoolInitial extends JoinPoolState {}

class JoinPoolLoading extends JoinPoolState {
  final String poolId;
  JoinPoolLoading(this.poolId);
}

class JoinPoolSuccess extends JoinPoolState {
  final String poolId;
  final JoinPoolModel model;
  JoinPoolSuccess(this.poolId, this.model);
}

class JoinPoolFailure extends JoinPoolState {
  final String poolId;
  final String message;
  JoinPoolFailure(this.poolId, this.message);
}
