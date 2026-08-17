import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/network/network_service.dart';
import 'package:local_basket/domain/usecase/cart/clearCart/clearCart_usecase.dart';
import 'package:local_basket/presentation/cubit/cart/clearCart/clearCart_state.dart';
import 'package:local_basket/presentation/cubit/cart/getCart/getCart_cubit.dart';
import 'package:local_basket/presentation/cubit/cart/getCart/getCart_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClearCartCubit extends Cubit<ClearCartState> {
  final ClearCartUseCase clearCartUseCase;
  final NetworkService networkService;
  ClearCartCubit(this.clearCartUseCase, this.networkService)
      : super(ClearCartInitial());

  Future<void> clearCart(
    BuildContext context, {
    String? cartId,
  }) async {
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
      emit(ClearCartLoading());
      try {
        final resolvedCartId = await _resolveCartId(context, cartId);
        if (resolvedCartId == null || resolvedCartId.isEmpty) {
          throw Exception('Cart id not found');
        }
        final result = await clearCartUseCase(resolvedCartId);
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('cart_id');
        emit(ClearCartSuccess(result));
      } catch (e) {
        emit(ClearCartFailure(friendlyErrorMessage(e)));
      }
    }
  }

  Future<String?> _resolveCartId(BuildContext context, String? cartId) async {
    if (cartId != null && cartId.isNotEmpty) return cartId;

    final cartState = context.read<GetCartCubit>().state;
    if (cartState is GetCartLoaded) {
      final id = cartState.cart.id;
      if (id != null && id.isNotEmpty) return id;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('cart_id');
  }
}
