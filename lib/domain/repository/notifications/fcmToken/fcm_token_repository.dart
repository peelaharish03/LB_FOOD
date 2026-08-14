import 'package:local_basket/data/model/notifications/fcmToken/fcm_token_model.dart';

abstract class FcmTokenRepository {
  Future<FcmTokenModel> updateFcmToken({
    required String fcmToken,
    required String deviceType,
  });

  Future<FcmTokenModel> getFcmToken();
}
