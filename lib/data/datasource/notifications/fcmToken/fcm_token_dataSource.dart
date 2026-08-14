import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/notifications/fcmToken/fcm_token_model.dart';

abstract class FcmTokenRemoteDataSource {
  Future<FcmTokenModel> updateFcmToken({
    required String fcmToken,
    required String deviceType,
  });

  Future<FcmTokenModel> getFcmToken();
}

class FcmTokenRemoteDataSourceImpl implements FcmTokenRemoteDataSource {
  final Dio client;

  FcmTokenRemoteDataSourceImpl({required this.client});

  @override
  Future<FcmTokenModel> updateFcmToken({
    required String fcmToken,
    required String deviceType,
  }) async {
    try {
      final response = await client.put(
        '$baseUrl2$fcmTokenUrl',
        data: {
          'fcmToken': fcmToken,
          'deviceType': deviceType,
        },
      );

      debugPrint('FCM token stored response: ${response.data}');

      if (response.statusCode == 200) {
        return FcmTokenModel.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to update FCM token: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Failed to update FCM token: $e');
      throw Exception('Failed to update FCM token: ${e.toString()}');
    }
  }

  @override
  Future<FcmTokenModel> getFcmToken() async {
    try {
      final response = await client.get('$baseUrl2$fcmTokenUrl');

      debugPrint('Stored FCM token response: ${response.data}');

      if (response.statusCode == 200) {
        final model = FcmTokenModel.fromJson(response.data);
        debugPrint('Stored FCM token: ${model.fcmToken}');
        debugPrint(
          'FCM token deviceType: ${model.deviceType}, '
          'hasToken: ${model.hasToken}',
        );
        return model;
      } else {
        throw Exception('Failed to get FCM token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      throw Exception('Failed to get FCM token: ${e.toString()}');
    }
  }
}
