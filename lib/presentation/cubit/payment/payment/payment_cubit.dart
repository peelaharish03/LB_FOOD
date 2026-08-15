import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/core/network/network_service.dart';
import 'package:local_basket/data/model/payment/payment_model.dart';
import 'package:local_basket/domain/usecase/payment/payment_usecase.dart';
import 'package:local_basket/presentation/cubit/orders/createOrder/createOrder_cubit.dart';
import 'package:local_basket/presentation/cubit/payment/payment/payment_state.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final PaymentUseCase paymentUseCase;
  final NetworkService networkService;

  PaymentCubit(this.paymentUseCase, this.networkService)
      : super(PaymentInitial());

  Future<void> makePayment({
    required BuildContext context,
    required String paymentType,
    Map<String, dynamic>? paymentPayload,
  }) async {
    print('Payment type: $paymentType');
    print('Payment payload: $paymentPayload');

    final bool isConnected = await networkService.hasInternetConnection();
    print('Internet connected: $isConnected');

    if (!isConnected) {
      CustomSnackbars.showErrorSnack(
        context: context,
        title: 'Alert',
        message: 'Please check Internet Connection',
      );
      return;
    }

    emit(PaymentLoading());

    try {
      if (paymentType == 'ONLINE' && paymentPayload != null) {
        // Process online payment
        final result = await paymentUseCase(paymentPayload);
        print('Payment result: ${result.status}');

        if (result.status == 'Verified') {
          // Order is placed only here, once, after payment is confirmed
          // verified by the backend — never before payment, and never if
          // verification fails.
          final createOrderCubit = context.read<CreateOrderCubit>();
          await createOrderCubit.createOrder(
            context,
            paymentId: paymentPayload['paymentId'],
            paymentType: 'RAZORPAY',
          );
          emit(PaymentSuccess(result));
        } else {
          emit(
            PaymentFailure(
              'Payment could not be verified. If any amount was deducted, it will be refunded within 24 hours.',
            ),
          );
        }
      } else if (paymentType == 'CASH') {
        // Process COD payment directly
        final createOrderCubit = context.read<CreateOrderCubit>();
        await createOrderCubit.createOrder(
          context,
          paymentType: paymentType,
        );
        // Create a success response for COD
        emit(PaymentSuccess(
          PaymentModel(
            message: 'Order placed with Cash on Delivery',
            status: 'Success',
          ),
        ));
      } else {
        throw Exception('Invalid payment type or missing payment payload');
      }
    } catch (e) {
      print('Payment error: $e');
      emit(PaymentFailure(e.toString()));
    }
  }

  // Logs a failed payment to the backend. Intentionally does not emit
  // PaymentSuccess/PaymentFailure — the caller already shows the failure
  // UI from the Razorpay callback, and a 200 here just means the failure
  // was recorded, not that the payment succeeded.
  Future<void> makePaymentFailure({
    required BuildContext context,
    Map<String, dynamic>? paymentPayload,
  }) async {
    if (paymentPayload == null) return;

    final bool isConnected = await networkService.hasInternetConnection();
    print('Internet connected: $isConnected');
    if (!isConnected) return;

    try {
      final result = await paymentUseCase(paymentPayload);
      print('Payment failure logged: ${result.status}');
    } catch (e) {
      print('Payment failure logging error: $e');
    }
  }

  Future<void> paymentTracking(String paymentId, BuildContext context) async {
    final bool isConnected = await networkService.hasInternetConnection();
    print('Internet connected: $isConnected');

    if (!isConnected) {
      CustomSnackbars.showErrorSnack(
        context: context,
        title: 'Alert',
        message: 'Please check Internet Connection',
      );
      return;
    }

    emit(PaymentLoading());

    try {
      final result = await paymentUseCase.Payment_Tracking(paymentId);
      emit(PaymentTrackingSuccess(result));
    } catch (e) {
      print('Payment tracking error: $e');
      emit(PaymentFailure(e.toString()));
    }
  }

  Future<void> paymentRefund(String paymentId, BuildContext context) async {
    final bool isConnected = await networkService.hasInternetConnection();
    print('Internet connected: $isConnected');

    if (!isConnected) {
      CustomSnackbars.showErrorSnack(
        context: context,
        title: 'Alert',
        message: 'Please check Internet Connection',
      );
      return;
    }

    emit(PaymentRefundLoading());

    try {
      final result = await paymentUseCase.Payment_Refund(paymentId);
      print('Payment refund result: ${result.status}');

      if (result.status == 'REFUNDED') {
        Future.delayed(Duration(milliseconds: 200), () {
          if (context.mounted) {
            CustomSnackbars.showErrorSnack(
              context: context,
              title: 'Alert',
              message:
                  'Your order was not confirmed, if any amount was deducted, it will be refunded within 24 hours.',
            );
          }
        });

        emit(PaymentRefundSuccess(result));
      }
    } catch (e) {
      print('Payment refund error: $e');
      emit(PaymentRefundFailure(e.toString()));
    }
  }
}
