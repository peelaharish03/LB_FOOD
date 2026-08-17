import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/network/network_service.dart';
import 'package:local_basket/domain/usecase/authentication/update_current_customer_usecase.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/update/update_current_customer_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpdateCurrentCustomerCubit extends Cubit<UpdateCurrentCustomerState> {
  final UpdateCurrentCustomerUseCase useCase;
  final NetworkService networkService;

  UpdateCurrentCustomerCubit(
      {required this.useCase, required this.networkService})
      : super(UpdateCurrentCustomerState());

 bool _isUpdating = false;

Future<void> updateCustomer(Map<String, dynamic> payload, context) async {
  if (_isUpdating) return;

  _isUpdating = true;
  bool isConnected = await networkService.hasInternetConnection();
  if (!isConnected) {
    CustomSnackbars.showErrorSnack(
      context: context,
      title: 'Alert',
      message: 'Please check Internet Connection',
    );
    _isUpdating = false;
    return;
  }

  emit(state.copyWith(isLoading: true, error: null));
  try {
    final result = await useCase(payload);
    emit(state.copyWith(isLoading: false, data: result));
  } catch (e) {
    emit(state.copyWith(isLoading: false, error: friendlyErrorMessage(e)));
  } finally {
    _isUpdating = false;
  }
}

}
