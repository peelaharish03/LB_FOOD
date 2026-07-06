import 'package:bloc/bloc.dart';
import 'package:local_basket/domain/usecase/authentication/signup_usecase.dart';
import 'package:flutter/material.dart';
import '../../../../components/custom_snackbar.dart';
import '../../../../core/network/network_helper.dart';
import '../../../../core/network/network_service.dart';
import '../../../screen/authentication/otp_screen.dart';
import 'signup_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  final SignUpValidationUseCase useCase;
  final NetworkService networkService;

  SignUpCubit({required this.useCase, required this.networkService})
      : super(SignUpInitial());

  Future<void> fetchOtp(BuildContext context, String mobileNumber,String fullName) async {
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
    }

    if (mobileNumber.isEmpty) {
      CustomSnackbars.showErrorSnack(
        context: context,
        title: 'Attention',
        message: 'Please enter a mobile number',
      );
      return;
    } else if (mobileNumber.length < 10) {
      CustomSnackbars.showErrorSnack(
        context: context,
        message: 'Please enter a valid mobile number',
        title: 'Attention',
      );
      return;
    }

    try {
      emit(SignUpLoading());
      final otpEntity = await useCase(mobileNumber);
      emit(SignUpLoaded(otpEntity));

      final otpValue =
          otpEntity.otp?.isNotEmpty == true ? otpEntity.otp! : 'true';

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            primaryContact: mobileNumber,
            otp: otpValue,
            fullName: fullName,
            deviceId: '',
          ),
        ),
        (route) => false,
      );

      print('OTP response received and stored in state');
    } catch (e) {
      print('error in trigger otp: $e');
      emit(SignUpError('Failed to load OTP data: ${e.toString()}'));
    }
  }

  Future<void> resendOtp(BuildContext context, String mobileNumber) async {
    bool isConnected = await NetworkHelper.checkInternetAndShowSnackbar(
      context: context,
      networkService: networkService,
    );
    if (!isConnected) return;

    try {
      final otpEntity = await useCase(mobileNumber);
      emit(ResendOtpLoaded(otpEntity));
      if (otpEntity.creationTime?.isNotEmpty == true) {
        final otpValue =
            otpEntity.otp?.isNotEmpty == true ? otpEntity.otp! : 'true';
        print(otpValue);
      } else {
        CustomSnackbars.showErrorSnack(
          context: context,
          title: 'Alert',
          message: 'Something went wrong, please try again later',
        );
      }
    } catch (e) {
      print(e);
    }
  }
}

