import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

import '../../../../components/custom_snackbar.dart';
import '../../../../core/network/network_helper.dart';
import '../../../../core/network/network_service.dart';
import '../../../../domain/usecase/authentication/trigger_otp_usecase.dart';
import '../../../screen/authentication/otp_screen.dart';
import 'trigger_otp_state.dart';

class TriggerOtpCubit extends Cubit<TriggerOtpState> {
  final TriggerOtpValidationUseCase useCase;
  final NetworkService networkService;

  TriggerOtpCubit({
    required this.useCase,
    required this.networkService,
  }) : super(TriggerOtpInitial());

  /// Get Device ID
  Future<String> getDeviceId() async {
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

        // You can use fingerprint, id, model, etc.
        return androidInfo.fingerprint;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? '';
      }
    } catch (e) {
      debugPrint("Error fetching device id: $e");
    }

    return '';
  }

  Future<void> fetchOtp(
    BuildContext context,
    String primaryContact,
  ) async {
    bool isConnected = await networkService.hasInternetConnection();

    if (!isConnected) {
      CustomSnackbars.showErrorSnack(
        context: context,
        title: 'Alert',
        message: 'Please check Internet Connection',
      );
      return;
    }

    if (primaryContact.isEmpty) {
      CustomSnackbars.showErrorSnack(
        context: context,
        title: 'Attention',
        message: 'Please enter a mobile number',
      );
      return;
    }

    if (primaryContact.length < 10) {
      CustomSnackbars.showErrorSnack(
        context: context,
        title: 'Attention',
        message: 'Please enter a valid mobile number',
      );
      return;
    }

    try {
      emit(TriggerOtpLoading());

      final otpEntity = await useCase(primaryContact);

      emit(TriggerOtpLoaded(otpEntity));

      final otpValue = otpEntity.otp ?? '';

      /// Fetch actual device id
      final String deviceId = await getDeviceId();

      debugPrint("Device ID: $deviceId");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            primaryContact: primaryContact,
            otp: otpValue,
            fullName: '',
            deviceId: deviceId,
          ),
        ),
        (route) => false,
      );

      debugPrint('OTP response received and stored in state');
    } catch (e) {
      debugPrint('Error in trigger otp: $e');

      emit(
        TriggerOtpError(
          'Failed to load OTP data: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> resendOtp(
    BuildContext context,
    String mobileNumber,
  ) async {
    bool isConnected = await NetworkHelper.checkInternetAndShowSnackbar(
      context: context,
      networkService: networkService,
    );

    if (!isConnected) return;

    try {
      final otpEntity = await useCase(mobileNumber);

      emit(ResendOtpLoaded(otpEntity));

      if (otpEntity.otp?.isNotEmpty == true) {
        final otpValue = otpEntity.otp!;
        debugPrint("Resend OTP: $otpValue");
      } else {
        CustomSnackbars.showErrorSnack(
          context: context,
          title: 'Alert',
          message: 'Something went wrong, please try again later',
        );
      }
    } catch (e) {
      debugPrint("Resend OTP Error: $e");
    }
  }
}