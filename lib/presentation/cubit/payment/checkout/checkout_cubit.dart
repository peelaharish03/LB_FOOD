import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/domain/usecase/payment/checkout_usecase.dart';
import 'checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final CheckoutUseCase useCase;

  CheckoutCubit({required this.useCase}) : super(CheckoutInitial());

  Future<void> fetchCheckout() async {
    emit(CheckoutLoading());

    try {
      final result = await useCase();
      emit(CheckoutSuccess(model: result));
    } catch (e) {
      emit(CheckoutFailure(error: e.toString()));
    }
  }
}
