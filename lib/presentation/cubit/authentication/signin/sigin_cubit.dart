import 'package:local_basket/components/custom_snackbar.dart';
import 'package:local_basket/core/constants/global_exception_handler.dart';
import 'package:local_basket/core/network/network_service.dart';
import 'package:local_basket/presentation/cubit/authentication/currentcustomer/get/current_customer_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../domain/usecase/authentication/signin_usecase.dart';
import 'signin_state.dart';

class SignInCubit extends Cubit<SignInState> {
  final SignInValidationUseCase useCase;
  final NetworkService networkService;
  SignInCubit({required this.useCase, required this.networkService})
      : super(SignInInitial());

  Future<void> signIn(BuildContext context, String mobileNumber, String otp, String deviceId,
      String fullName) async {
    bool isConnected = await networkService.hasInternetConnection();
    if (!isConnected) {
      CustomSnackbars.showErrorSnack(
        context: context,
        title: 'Alert',
        message: 'Please check Internet Connection',
      );
      return;
    } else {
      if (otp.isEmpty || otp.length < 6) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: Text(
                otp.isEmpty ? 'Please enter otp' : 'Please enter valid otp'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      try {
        emit(SignInLoading());
        final signEntity = await useCase(mobileNumber, otp, fullName, 'device-uuid-123');

        if (signEntity.accessToken != null && signEntity.accessToken!.isNotEmpty) {
          final storage = FlutterSecureStorage();
          await storage.write(key: 'TOKEN', value: signEntity.accessToken ?? '');
          await storage.write(key: 'REFRESH_TOKEN', value: signEntity.refreshToken ?? '');
          context.read<CurrentCustomerCubit>().GetCurrentCustomer(context);
        } else {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Error'),
              content: const Text('Invalid OTP'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }

        emit(SignInLoaded(signEntity));
      } on AppException catch (e) {
        debugPrint('Sign in error: $e');
        final message =
            e is BadRequestException || e is NotFoundException || e is NetworkException || e is RequestTimeoutException
                ? e.message
                : 'Unable to verify OTP at this moment. Please try again after some time.';
        emit(SignInError(message));
      } catch (e) {
        debugPrint('Sign in error: $e');
        emit(SignInError('Unable to verify OTP at this moment. Please try again after some time.'));
      }
    }
  }
}
