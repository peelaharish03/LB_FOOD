import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/core/network/network_service.dart';
import 'package:local_basket/domain/usecase/address/defaultAddress/post/defaultAddress_usecase.dart';
import 'package:local_basket/presentation/cubit/address/defaultAddress/post/defaultAddress_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DefaultAddressCubit extends Cubit<DefaultAddressState> {
  final DefaultAddressUseCase useCase;
  final NetworkService networkService;

  DefaultAddressCubit(this.useCase, this.networkService)
    : super(DefaultAddressInitial());

  Future<void> setDefaultAddress(String addressId, context) async {
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
      emit(DefaultAddressLoading());
      try {
        final result = await useCase(addressId);
        emit(DefaultAddressSuccess(defaultAddressModel: result));
      } catch (e) {
        emit(DefaultAddressFailure(error: e.toString()));
      }
    }
  }
}
