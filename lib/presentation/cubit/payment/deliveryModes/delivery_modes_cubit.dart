import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/domain/usecase/payment/deliveryModes/delivery_modes_usecase.dart';
import 'delivery_modes_state.dart';

class DeliveryModesCubit extends Cubit<DeliveryModesState> {
  final DeliveryModesUseCase useCase;

  DeliveryModesCubit(this.useCase) : super(DeliveryModesInitial());

  Future<void> fetchDeliveryModes() async {
    emit(DeliveryModesLoading());
    try {
      final result = await useCase();
      emit(DeliveryModesLoaded(model: result));
    } catch (e) {
      emit(DeliveryModesFailure(error: friendlyErrorMessage(e)));
    }
  }
}
