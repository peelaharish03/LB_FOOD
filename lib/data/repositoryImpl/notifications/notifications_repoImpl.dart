import 'package:local_basket/data/datasource/notifications/notifications_datasource.dart';
import 'package:local_basket/data/model/notifications/clear_notifications_model.dart';
import 'package:local_basket/data/model/notifications/notifications_model.dart';
import 'package:local_basket/domain/repository/notifications/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final GetNotificationsRemoteDataSource remoteDataSource;

  NotificationsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<GetNotificationsModel> getNotifications() async {
    return await remoteDataSource.getNotifications();
  }

  @override
  Future<ClearNotificationsModel> clearNotifications() async {
    return await remoteDataSource.clearNotifications();
  }
}
