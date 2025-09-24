import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/domain/usecase/offers/restaurant_offers/validate_offer_usecase.dart';
import 'package:local_basket/presentation/cubit/offers/restaurant_offers/validate_offers/validate_offer_state.dart';

class ValidateOfferCubit extends Cubit<ValidateOfferState> {
  final ValidateOfferUseCase validateOfferUseCase;

  ValidateOfferCubit(this.validateOfferUseCase)
      : super(ValidateOfferInitial());

  Future<void> validateOffer() async {
    emit(ValidateOfferLoading());
    try {
      final result = await validateOfferUseCase.call();
      emit(ValidateOfferSuccess(validateOfferModel: result));
    } catch (e) {
      emit(ValidateOfferFailure(error: e.toString()));
    }
  }
}
