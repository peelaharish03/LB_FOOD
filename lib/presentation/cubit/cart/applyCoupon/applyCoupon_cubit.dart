import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/network/network_service.dart';
import 'package:local_basket/domain/usecase/cart/applyCoupon/applyCoupon_usecase.dart';
import 'package:local_basket/presentation/cubit/cart/applyCoupon/applyCoupon_state.dart';

class ApplyCouponCubit extends Cubit<ApplyCouponState> {
  final ApplyCouponUseCase applyCouponUseCase;
  final NetworkService networkService;

  ApplyCouponCubit(this.applyCouponUseCase, this.networkService)
    : super(ApplyCouponInitial());

  /// Applies [code] to the cart via `POST /api/carts/{cartId}/coupon`.
  /// Returns true on success.
  Future<bool> applyCoupon(String cartId, String code, {context}) async {
    return _run(
      cartId: cartId,
      code: code,
      context: context,
      action: () => applyCouponUseCase.apply(cartId, code),
    );
  }

  /// Removes [code] from the cart via `DELETE /api/carts/{cartId}/coupon`.
  /// Returns true on success.
  Future<bool> removeCoupon(String cartId, String code, {context}) async {
    return _run(
      cartId: cartId,
      code: null,
      context: context,
      action: () => applyCouponUseCase.remove(cartId, code),
    );
  }

  Future<bool> _run({
    required String cartId,
    required String? code,
    required dynamic context,
    required Future<void> Function() action,
  }) async {
    if (!_hasValidId(cartId)) {
      emit(ApplyCouponFailure('Cart id is missing'));
      return false;
    }

    final isConnected = await networkService.hasInternetConnection();
    if (!isConnected) {
      if (context != null) {
        CustomSnackbars.showErrorSnack(
          context: context,
          title: 'Alert',
          message: 'Please check Internet Connection',
        );
      }
      emit(ApplyCouponFailure('Please check Internet Connection'));
      return false;
    }

    emit(ApplyCouponLoading(code: code));
    try {
      await action();
      emit(ApplyCouponSuccess(code: code));
      return true;
    } catch (e) {
      emit(ApplyCouponFailure(friendlyErrorMessage(e)));
      return false;
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
