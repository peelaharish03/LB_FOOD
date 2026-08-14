import 'package:local_basket/data/model/orders/orderHistory/orderHistory_model.dart';

abstract class OrderHistoryState {}

class OrderHistoryInitial extends OrderHistoryState {}

class OrderHistoryLoading extends OrderHistoryState {
  final int page;

  OrderHistoryLoading({required this.page});
}

class OrderHistoryLoaded extends OrderHistoryState {
  final OrderHistoryModel orders;
  final int page;
  final int size;
  final String searchQuery;

  OrderHistoryLoaded(
    this.orders, {
    required this.page,
    required this.size,
    required this.searchQuery,
  });
}

class OrderHistoryError extends OrderHistoryState {
  final String message;
  final int page;

  OrderHistoryError(this.message, {required this.page});
}
