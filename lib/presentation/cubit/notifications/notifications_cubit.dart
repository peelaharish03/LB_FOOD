import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_basket/domain/usecase/notifications/notifications_usecase.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final ClearNotificationsUseCase clearNotificationsUseCase;

  NotificationsCubit({
    required this.getNotificationsUseCase,
    required this.clearNotificationsUseCase,
  }) : super(NotificationsInitial());

  // GET notifications
  Future<void> fetchNotifications() async {
    emit(NotificationsLoading());

    try {
      final response = await getNotificationsUseCase();
      emit(NotificationsLoaded(response));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  // CLEAR notifications
  Future<void> clearNotifications() async {
    emit(ClearNotificationsLoading());

    try {
      final result = await clearNotificationsUseCase();
      emit(ClearNotificationsSuccess(result));
    } catch (e) {
      emit(ClearNotificationsError(e.toString()));
    }
  }
}
