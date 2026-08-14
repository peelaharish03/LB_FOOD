import 'package:local_basket/data/model/notifications/fcmToken/fcm_token_model.dart';

class FcmTokenState {}

class FcmTokenInitial extends FcmTokenState {}

class FcmTokenStoring extends FcmTokenState {}

class FcmTokenStored extends FcmTokenState {
  final FcmTokenModel result;
  FcmTokenStored(this.result);
}

class FcmTokenFetching extends FcmTokenState {}

class FcmTokenFetched extends FcmTokenState {
  final FcmTokenModel result;
  FcmTokenFetched(this.result);
}

class FcmTokenError extends FcmTokenState {
  final String message;
  FcmTokenError(this.message);
}
