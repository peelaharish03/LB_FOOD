import 'package:local_basket/data/model/notifications/fcmToken/fcm_token_model.dart';
import 'package:local_basket/domain/repository/notifications/fcmToken/fcm_token_repository.dart';

class StoreFcmTokenUseCase {
  final FcmTokenRepository repository;

  StoreFcmTokenUseCase({required this.repository});

  Future<FcmTokenModel> call({
    required String fcmToken,
    required String deviceType,
  }) async {
    return await repository.updateFcmToken(
      fcmToken: fcmToken,
      deviceType: deviceType,
    );
  }
}

class GetFcmTokenUseCase {
  final FcmTokenRepository repository;

  GetFcmTokenUseCase({required this.repository});

  Future<FcmTokenModel> call() async {
    return await repository.getFcmToken();
  }
}
