import 'package:local_basket/data/model/notifications/clear_notifications_model.dart';
import 'package:local_basket/data/model/notifications/notifications_model.dart';
import 'package:local_basket/domain/repository/notifications/notifications_repository.dart';

class GetNotificationsUseCase {
  final NotificationsRepository repository;

  GetNotificationsUseCase({required this.repository});

  Future<GetNotificationsModel> call() async {
    return await repository.getNotifications();
  }
}

class ClearNotificationsUseCase {
  final NotificationsRepository repository;

  ClearNotificationsUseCase({required this.repository});

  Future<ClearNotificationsModel> call() async {
    return await repository.clearNotifications();
  }
}