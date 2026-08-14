import 'package:flutter_bloc/flutter_bloc.dart';
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
      emit(CheckoutFailure(error: _cleanError(e)));
      return null;
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}
