import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/network/network_service.dart';
import 'package:local_basket/data/model/address/deleteAddress/deleteAddress_model.dart';
import 'package:local_basket/domain/usecase/address/deleteAddress/deleteAddress_usecase.dart';
import 'package:local_basket/domain/usecase/address/getAddress/getAddress_usecase.dart';
import 'package:local_basket/presentation/cubit/address/deleteAddress/deleteAddress_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteAddressCubit extends Cubit<DeleteAddressState> {
  final DeleteAddressUseCase usecase;
  final GetAddressUseCase getAddressUseCase;
  final NetworkService networkService;
  DeleteAddressCubit(this.usecase, this.getAddressUseCase, this.networkService)
    : super(DeleteAddressInitial());

  Future<void> deleteAddress(String addressId, context) async {
    bool isConnected = await networkService.hasInternetConnection();
    print("addressId: $addressId");
    print(isConnected);
    if (!isConnected) {
      print("No Internet Connection");
      CustomSnackbars.showErrorSnack(
        context: context,
        title: 'Alert',
        message: 'Please check Internet Connection',
      );
      return;
    }

    emit(DeleteAddressLoading());

    // Fire the delete call, but don't trust its response body alone — the
    // endpoint sometimes returns a misleading payload even when the row was
    // actually removed. Keep whatever it returned/threw and reconcile it
    // against a fresh address list below.
    DeleteAddressModel? deleteResult;
    Object? deleteError;
    try {
      deleteResult = await usecase.execute(addressId);
    } catch (e) {
      deleteError = e;
    }

    try {
      final addresses = await getAddressUseCase();
      final stillExists =
          addresses.content.any((address) => address.id == addressId);

      if (!stillExists) {
        // The address is gone from the list → deletion succeeded regardless
        // of what the delete response said.
        emit(
          DeleteAddressSuccess(
            deleteResult ??
                DeleteAddressModel(
                  success: true,
                  data: null,
                  message: 'Address Deleted Successfully',
                ),
          ),
        );
        return;
      }

      // The address is still in the list → deletion really did fail.
      emit(
        DeleteAddressFailure(
          deleteError != null
              ? friendlyErrorMessage(deleteError)
              : (deleteResult?.message?.isNotEmpty == true
                  ? deleteResult!.message!
                  : 'Failed to delete address'),
        ),
      );
    } catch (e) {
      // Couldn't confirm via the list — fall back to the delete call's own
      // outcome.
      if (deleteError != null) {
        emit(DeleteAddressFailure(friendlyErrorMessage(deleteError)));
      } else {
        emit(DeleteAddressSuccess(deleteResult!));
      }
    }
  }
}
