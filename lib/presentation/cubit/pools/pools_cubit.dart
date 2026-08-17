import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
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
      emit(PoolsError(friendlyErrorMessage(e)));
    }
  }

  /// Re-fetches pools without emitting [PoolsLoading], so polling in the
  /// background doesn't flash a spinner over the current list. Failures are
  /// swallowed so a flaky poll doesn't disrupt whatever is on screen.
  Future<void> refreshPoolsSilently() async {
    try {
      final response = await getPoolsUseCase();
      emit(PoolsLoaded(response));
    } catch (_) {}
  }
}
