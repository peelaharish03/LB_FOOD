import 'package:local_basket/data/model/notifications/clear_notifications_model.dart';
import 'package:local_basket/data/model/notifications/notifications_model.dart';

abstract class NotificationsRepository {
  Future<GetNotificationsModel> getNotifications();
  Future<ClearNotificationsModel> clearNotifications();
}
