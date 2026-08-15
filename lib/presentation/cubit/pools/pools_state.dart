import 'package:local_basket/data/model/pools/pools_model.dart';

class PoolsState {}

class PoolsInitial extends PoolsState {}

class PoolsLoading extends PoolsState {}

class PoolsLoaded extends PoolsState {
  final PoolsModel pools;
  PoolsLoaded(this.pools);
}

class PoolsError extends PoolsState {
  final String message;
  PoolsError(this.message);
}
