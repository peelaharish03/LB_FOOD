import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/domain/usecase/pools/pools_usecase.dart';
import 'pools_state.dart';

class PoolsCubit extends Cubit<PoolsState> {
  final GetPoolsUseCase getPoolsUseCase;

  PoolsCubit({required this.getPoolsUseCase}) : super(PoolsInitial());

  Future<void> fetchPools() async {
    emit(PoolsLoading());

    try {
      final response = await getPoolsUseCase();
      emit(PoolsLoaded(response));
    } catch (e) {
      emit(PoolsError(e.toString()));
    }
  }
}
