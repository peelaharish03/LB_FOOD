import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/core/network/network_service.dart';
import 'package:local_basket/domain/usecase/orders/createOrder/createOrder_usecase.dart';
import 'package:local_basket/presentation/cubit/cart/clearCart/clearCart_cubit.dart';
import 'package:local_basket/presentation/cubit/orders/createOrder/createOrder_state.dart';
import 'package:local_basket/presentation/cubit/payment/payment/payment_cubit.dart';
import 'package:local_basket/presentation/screen/order/orderSuccess_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateOrderCubit extends Cubit<CreateOrderState> {
  final CreateOrderUseCase useCase;
  final NetworkService networkService;

  CreateOrderCubit(this.useCase, this.networkService)
      : super(CreateOrderInitial());

  Future<void> createOrder(
    BuildContext context, {
    String? paymentId,
    required String paymentType,
  }) async {
    bool isConnected = await networkService.hasInternetConnection();
    print('Internet connected: $isConnected');

    if (!isConnected) {
      CustomSnackbars.showErrorSnack(
        context: context,
        title: 'Alert',
        message: 'Please check Internet Connection',
      );
      return;
    }

    final Map<String, dynamic> payload = {
      'paymentType': paymentType,
    };

    // Only add paymentTransactionId for online payments
    if (paymentType == 'ONLINE' && paymentId != null) {
      payload['paymentTransactionId'] = paymentId;
    }

    emit(CreateOrderLoading());
    try {
      final order = await useCase(payload);
      print('order: ${order.status}');
      if (order.status == "success") {
        final clearCartCubit = context.read<ClearCartCubit>();
        await clearCartCubit.clearCart(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
        );
        emit(CreateOrderLoaded(order));
      } else if (paymentType == 'ONLINE' && paymentId != null) {
        // Only attempt refund for failed online payments
        final paymentCubit = context.read<PaymentCubit>();
        await paymentCubit.paymentRefund(paymentId, context);
      }
    } catch (e) {
      // Only attempt refund for online payments if paymentId is available
      if (paymentType == 'ONLINE' && paymentId != null) {
        final paymentCubit = context.read<PaymentCubit>();
        await paymentCubit.paymentRefund(paymentId, context);
      }

      print('CreateOrder error: $e');
      emit(CreateOrderError(e.toString()));
    }
  }
}
