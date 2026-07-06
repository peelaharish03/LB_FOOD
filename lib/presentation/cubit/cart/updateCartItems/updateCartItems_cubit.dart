import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/core/network/network_service.dart';
import 'package:local_basket/domain/usecase/cart/updateCartItems/updateCartItems_usecase.dart';
import 'package:local_basket/presentation/cubit/cart/updateCartItems/updateCartItems_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpdateCartItemsCubit extends Cubit<UpdateCartItemsState> {
  final UpdateCartItemsUseCase updateCartItemsUseCase;
  final NetworkService networkService;
  UpdateCartItemsCubit(this.updateCartItemsUseCase, this.networkService)
    : super(UpdateCartItemsInitial());

  Future<void> updateCartItem(
    Map<String, dynamic> payload,
    String cartId,
    String itemId,
    context,
  ) async {
    if (!_hasValidId(cartId) || !_hasValidId(itemId)) {
      emit(UpdateCartItemsFailure('Cart id or item id is missing'));
      return;
    }

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
      emit(UpdateCartItemsLoading());
      try {
        final result = await updateCartItemsUseCase(payload, cartId, itemId);
        emit(UpdateCartItemsSuccess(result));
      } catch (e) {
        emit(UpdateCartItemsFailure(e.toString()));
      }
    }
  }

  bool _hasValidId(String? id) {
    final normalized = id?.trim();
    return normalized != null &&
        normalized.isNotEmpty &&
        normalized != '0' &&
        normalized.toLowerCase() != 'null';
  }
}
