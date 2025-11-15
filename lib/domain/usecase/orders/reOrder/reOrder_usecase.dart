import 'package:local_basket/data/model/orders/reOrder/reOrder_model.dart';
import 'package:local_basket/domain/repository/orders/reOrder/reOrder_repository.dart';

class ReOrderUseCase {
  final ReOrderRepository repository;

  ReOrderUseCase({required this.repository});

  Future<ReOrderModel> call(
    dynamic payload,
  ) async {
    return await repository.reOrder(payload);
  }
}
