import 'package:local_basket/components/custom_snackbar.dart';
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

  Future<void> signIn(BuildContext context, String mobileNumber, String otp,
      String fullName) async {
    print(
        'trigger otp 1 mobileNumber: $mobileNumber -- OTP: $otp -- fullName: $fullName');
    bool isConnected = await networkService.hasInternetConnection();
    if (!isConnected) {
      print("No Internet Connection");
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
        final signEntity = await useCase(mobileNumber, otp, fullName);
        print('signEntity: $signEntity');

        if (signEntity.token != null && signEntity.token!.isNotEmpty) {
          final storage = FlutterSecureStorage();
          await storage.write(key: 'TOKEN', value: signEntity.token ?? '');
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
      } catch (e) {
        print('Sign in error: $e');
        emit(SignInError('Failed to validate OTP: ${e.toString()}'));
      }
    }
  }
}
