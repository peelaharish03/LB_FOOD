import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/domain/usecase/payment/paymentMethods/payment_methods_usecase.dart';
import 'payment_methods_state.dart';

class PaymentMethodsCubit extends Cubit<PaymentMethodsState> {
  final PaymentMethodsUseCase useCase;

  PaymentMethodsCubit(this.useCase) : super(PaymentMethodsInitial());

  Future<void> fetchPaymentMethods() async {
    emit(PaymentMethodsLoading());
    try {
      final result = await useCase();
      emit(PaymentMethodsLoaded(model: result));
    } catch (e) {
      emit(PaymentMethodsFailure(error: friendlyErrorMessage(e)));
    }
  }
}
