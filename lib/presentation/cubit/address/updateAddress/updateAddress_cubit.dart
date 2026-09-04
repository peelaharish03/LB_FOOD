import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/network/network_service.dart';
import 'package:local_basket/domain/usecase/address/updateAddress/updateAddress_usecase.dart';
import 'package:local_basket/presentation/cubit/address/updateAddress/updateAddress_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpdateAddressCubit extends Cubit<UpdateAddressState> {
  final UpdateAddressUseCase usecase;
  final NetworkService networkService;

  UpdateAddressCubit(this.usecase, this.networkService)
    : super(UpdateAddressInitial());

  Future<void> updateAddress(
    String addressId,
    Map<String, dynamic> payload,
    context,
  ) async {
    bool isConnected = await networkService.hasInternetConnection();
    if (!isConnected) {
      CustomSnackbars.showErrorSnack(
        context: context,
        title: 'Alert',
        message: 'Please check Internet Connection',
      );
      return;
    }

    emit(UpdateAddressLoading());
    try {
      final result = await usecase.call(addressId, payload);
      emit(UpdateAddressSuccess(result));
    } catch (e) {
      emit(UpdateAddressFailure(friendlyErrorMessage(e)));
    }
  }
}
