import 'package:dio/dio.dart';
import 'package:local_basket/core/constants/api_constants.dart';
import 'package:local_basket/data/model/notifications/clear_notifications_model.dart';
import 'package:local_basket/data/model/notifications/notifications_model.dart';


abstract class GetNotificationsRemoteDataSource {
  Future<GetNotificationsModel> getNotifications();
  Future<ClearNotificationsModel> clearNotifications();
}

class GetNotificationsRemoteDataSourceImpl
    implements GetNotificationsRemoteDataSource {
  final Dio client;

  GetNotificationsRemoteDataSourceImpl({required this.client});

  @override
  Future<GetNotificationsModel> getNotifications() async {
    try {
      // Default pagination; consider threading these through repository/usecase if needed
      const int pageNo = 0;
      const int pageSize = 20;
      final url = '$baseUrl${getNotificationsUrl(pageNo, pageSize)}';
      final response = await client.request(
        url,
        options: Options(method: 'GET'),
      );
      if (response.statusCode == 200) {
        print('responce of GetNotifications:: $response');
        return GetNotificationsModel.fromJson(response.data);
      } else {
        throw Exception(
            'Failed to load GetNotifications data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load GetNotifications data: ${e.toString()}');
    }
  }

  Future<ClearNotificationsModel> clearNotifications() async {
    try {
      final response = await client.request(
        '$baseUrl$clearAllNotificationsUrl',
        options: Options(method: 'DELETE'),
      );
      if (response.statusCode == 200) {
        print('responce of ClearNotifications:: $response');
        return ClearNotificationsModel.fromJson(response.data);
      } else {
        throw Exception(
            'Failed to load ClearNotifications data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load ClearNotifications data: ${e.toString()}');
    }
  }
}
