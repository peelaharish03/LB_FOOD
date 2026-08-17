import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/domain/usecase/pools/joinPool/joinPool_usecase.dart';
import 'joinPool_state.dart';

class JoinPoolCubit extends Cubit<JoinPoolState> {
  final JoinPoolUseCase joinPoolUseCase;

  JoinPoolCubit({required this.joinPoolUseCase}) : super(JoinPoolInitial());

  Future<void> joinPool(String poolId) async {
    emit(JoinPoolLoading(poolId));

    try {
      final response = await joinPoolUseCase(poolId);
      emit(JoinPoolSuccess(poolId, response));
    } catch (e) {
      emit(JoinPoolFailure(poolId, friendlyErrorMessage(e)));
    }
  }
}
