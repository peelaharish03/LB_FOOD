import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/network/network_service.dart';
import 'package:local_basket/domain/usecase/cart/productsAddToCart/productsAddtoCart_usecase.dart';
import 'package:local_basket/presentation/cubit/cart/productsAddToCart/productsAddtoCart_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductsAddToCartCubit extends Cubit<ProductsAddToCartState> {
  final ProductsAddToCartUseCase useCase;
  final NetworkService networkService;

  ProductsAddToCartCubit(this.useCase, this.networkService)
    : super(ProductsAddToCartInitial());

  Future<void> addToCart(
    cartId,
    Map<String, dynamic> payload, {
    context,
    bool forceReplace = false,
  }) async {
    final activeCartId = cartId?.toString();
    if (!_hasValidCartId(activeCartId)) {
      emit(ProductsAddToCartFailure('Cart id is missing'));
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
      emit(ProductsAddToCartLoading());
      try {
        final result = await useCase(
          activeCartId,
          payload,
          forceReplace: forceReplace,
        );
        emit(ProductsAddToCartSuccess(result));
      } catch (e) {
        if (e.toString().contains('403') &&
            context != null &&
            context.mounted) {
          final result = await useCase(
            activeCartId,
            payload,
            forceReplace: true,
          );
          emit(ProductsAddToCartSuccess(result));

          return;
        }
        emit(ProductsAddToCartFailure(friendlyErrorMessage(e)));
      }
    }
  }

  bool _hasValidCartId(String? id) {
    final normalized = id?.trim();
    return normalized != null &&
        normalized.isNotEmpty &&
        normalized != '0' &&
        normalized.toLowerCase() != 'null';
  }
}
