import 'package:local_basket/data/datasource/notifications/fcmToken/fcm_token_dataSource.dart';
import 'package:local_basket/data/model/notifications/fcmToken/fcm_token_model.dart';
import 'package:local_basket/domain/repository/notifications/fcmToken/fcm_token_repository.dart';

class FcmTokenRepositoryImpl implements FcmTokenRepository {
  final FcmTokenRemoteDataSource remoteDataSource;

  FcmTokenRepositoryImpl({required this.remoteDataSource});

  @override
  Future<FcmTokenModel> updateFcmToken({
    required String fcmToken,
    required String deviceType,
  }) {
    return remoteDataSource.updateFcmToken(
      fcmToken: fcmToken,
      deviceType: deviceType,
    );
  }

  @override
  Future<FcmTokenModel> getFcmToken() {
    return remoteDataSource.getFcmToken();
  }
}
