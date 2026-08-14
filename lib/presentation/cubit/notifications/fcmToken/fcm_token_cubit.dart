import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/domain/usecase/notifications/fcmToken/fcm_token_usecase.dart';
import 'fcm_token_state.dart';

class FcmTokenCubit extends Cubit<FcmTokenState> {
  final StoreFcmTokenUseCase storeFcmTokenUseCase;
  final GetFcmTokenUseCase getFcmTokenUseCase;

  FcmTokenCubit({
    required this.storeFcmTokenUseCase,
    required this.getFcmTokenUseCase,
  }) : super(FcmTokenInitial());

  Future<void> storeFcmToken({
    required String fcmToken,
    required String deviceType,
  }) async {
    emit(FcmTokenStoring());
    try {
      final result = await storeFcmTokenUseCase(
        fcmToken: fcmToken,
        deviceType: deviceType,
      );
      debugPrint('FCM token stored successfully: ${result.message}');
      emit(FcmTokenStored(result));
    } catch (e) {
      debugPrint('Store FCM token error: $e');
      emit(FcmTokenError(e.toString()));
    }
  }

  Future<void> fetchFcmToken() async {
    emit(FcmTokenFetching());
    try {
      final result = await getFcmTokenUseCase();
      debugPrint('Fetched stored FCM token: ${result.fcmToken}');
      emit(FcmTokenFetched(result));
    } catch (e) {
      debugPrint('Fetch FCM token error: $e');
      emit(FcmTokenError(e.toString()));
    }
  }
}
