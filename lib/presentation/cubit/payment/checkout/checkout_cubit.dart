import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/data/model/payment/checkout_model.dart';
import 'package:local_basket/domain/usecase/payment/checkout_usecase.dart';
import 'checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final CheckoutUseCase useCase;

  CheckoutCubit({required this.useCase}) : super(CheckoutInitial());

  Future<CheckoutModel?> fetchCheckout(Map<String, dynamic> payload) async {
    emit(CheckoutLoading());

    try {
      final result = await useCase(payload);
      emit(CheckoutSuccess(model: result));
      return result;
    } catch (e) {
      emit(CheckoutFailure(error: friendlyErrorMessage(e)));
      return null;
    }
  }

  /// Step 2 of the online-payment flow — returns the Razorpay order/key to
  /// open the payment sheet with, after [fetchCheckout] has succeeded.
  Future<CheckoutModel?> initiateCheckout(Map<String, dynamic> payload) async {
    emit(CheckoutLoading());

    try {
      final result = await useCase.initiate(payload);
      emit(CheckoutSuccess(model: result));
      return result;
    } catch (e) {
      emit(CheckoutFailure(error: friendlyErrorMessage(e)));
      return null;
    }
  }

  /// Cash-on-delivery checkout — creates the order directly.
  Future<CheckoutModel?> checkoutCod(Map<String, dynamic> payload) async {
    emit(CheckoutLoading());

    try {
      final result = await useCase.cod(payload);
      emit(CheckoutSuccess(model: result));
      return result;
    } catch (e) {
      emit(CheckoutFailure(error: friendlyErrorMessage(e)));
      return null;
    }
  }

  /// Reports the outcome of a Razorpay payment attempt (SUCCESS/FAILURE)
  /// back to the backend so the order can be confirmed or released.
  Future<CheckoutModel?> verifyPayment(Map<String, dynamic> payload) async {
    emit(CheckoutLoading());

    try {
      final result = await useCase.verifyPayment(payload);
      emit(CheckoutSuccess(model: result));
      return result;
    } catch (e) {
      emit(CheckoutFailure(error: friendlyErrorMessage(e)));
      return null;
    }
  }
}
