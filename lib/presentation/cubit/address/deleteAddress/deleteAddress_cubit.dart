import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/core/network/network_service.dart';
import 'package:local_basket/domain/usecase/address/deleteAddress/deleteAddress_usecase.dart';
import 'package:local_basket/presentation/cubit/address/deleteAddress/deleteAddress_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteAddressCubit extends Cubit<DeleteAddressState> {
  final DeleteAddressUseCase usecase;
  final NetworkService networkService;
  DeleteAddressCubit(this.usecase, this.networkService)
    : super(DeleteAddressInitial());

  Future<void> deleteAddress(String addressId, context) async {
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
      emit(DeleteAddressLoading());
      try {
        final result = await usecase.execute(addressId);
        emit(DeleteAddressSuccess(result));
      } catch (e) {
        emit(DeleteAddressFailure(e.toString()));
      }
    }
  }
}
