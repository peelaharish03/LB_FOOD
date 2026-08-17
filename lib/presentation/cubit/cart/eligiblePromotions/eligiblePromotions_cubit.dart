import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/domain/usecase/cart/eligiblePromotions/eligiblePromotions_usecase.dart';
import 'eligiblePromotions_state.dart';

class EligiblePromotionsCubit extends Cubit<EligiblePromotionsState> {
  final EligiblePromotionsUseCase useCase;

  EligiblePromotionsCubit(this.useCase) : super(EligiblePromotionsInitial());

  Future<void> fetchEligiblePromotions(Map<String, dynamic> payload) async {
    emit(EligiblePromotionsLoading());
    try {
      final result = await useCase(payload);
      emit(EligiblePromotionsLoaded(model: result));
    } catch (e) {
      emit(EligiblePromotionsFailure(error: friendlyErrorMessage(e)));
    }
  }
}
