import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/network/network_service.dart';
import 'package:local_basket/domain/usecase/address/saveAddress/saveAddress_usecase.dart';
import 'package:local_basket/presentation/cubit/address/saveAddress/saveAddress_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SaveAddressCubit extends Cubit<SaveAddressState> {
  final SaveAddressUseCase useCase;
  final NetworkService networkService;

  SaveAddressCubit(this.useCase, this.networkService)
      : super(SaveAddressInitial());

  Future<void> saveAddress(Map<String, dynamic> payload, context) async {
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
      emit(SaveAddressLoading());
      try {
        final result = await useCase.call(payload);
        emit(SaveAddressSuccess(result));
      } catch (e) {
        print(e);
        emit(SaveAddressFailure(friendlyErrorMessage(e)));
      }
    }
  }
}
