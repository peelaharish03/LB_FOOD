import 'package:local_basket/data/model/notifications/clear_notifications_model.dart';
import 'package:local_basket/data/model/notifications/notifications_model.dart';

class NotificationsState {}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final GetNotificationsModel notifications;
  NotificationsLoaded(this.notifications);
}

class NotificationsError extends NotificationsState {
  final String message;
  NotificationsError(this.message);
}

// Clear Notifications States
class ClearNotificationsLoading extends NotificationsState {}

class ClearNotificationsSuccess extends NotificationsState {
  final ClearNotificationsModel result;
  ClearNotificationsSuccess(this.result);
}

class ClearNotificationsError extends NotificationsState {
  final String message;
  ClearNotificationsError(this.message);
}
