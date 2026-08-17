import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/domain/usecase/offers/promotions/promotions_usecase.dart';
import 'package:local_basket/presentation/cubit/offers/promotions/promotions_state.dart';

class PromotionsCubit extends Cubit<PromotionsState> {
  final PromotionsUseCase getPromotionsUseCase;

  PromotionsCubit(this.getPromotionsUseCase) : super(PromotionsInitial());

  Future<void> fetchPromotions() async {
    try {
      emit(PromotionsLoading());
      final promotions = await getPromotionsUseCase.call();
      emit(PromotionsLoaded(promotions: promotions));
    } catch (e) {
      emit(PromotionsError(message: friendlyErrorMessage(e)));
    }
  }
}
