import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/network/network_service.dart';
import 'package:local_basket/domain/usecase/address/defaultAddress/get/getDefaultAddress_usecase.dart';
import 'package:local_basket/presentation/cubit/address/defaultAddress/get/getDefaultAddress_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddressSavetoCartCubit extends Cubit<AddressSavetoCartState> {
  final AddressSavetoCartUseCase useCase;
  final NetworkService networkService;
  AddressSavetoCartCubit(this.useCase, this.networkService)
    : super(AddressSavetoCartInitial());

  Future<void> addressSavetoCart(String addressId, context) async {
    bool isConnected = await networkService.hasInternetConnection();
    print(isConnected);
    if (!isConnected) {
      print("No Internet Connection");
      CustomSnackbars.showErrorSnack(
        context: context,
        title: 'Alert',
        message: 'Please check Internet Connection',
      );
      return;
    } else {
      try {
        emit(AddressSavetoCartLoading());
        final result = await useCase(addressId);
        emit(AddressSavetoCartSuccess(result));
      } catch (e) {
        emit(AddressSavetoCartFailure(friendlyErrorMessage(e)));
      }
    }
  }
}
