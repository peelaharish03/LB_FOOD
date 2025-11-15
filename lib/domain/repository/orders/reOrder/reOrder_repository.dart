import 'package:local_basket/data/model/orders/reOrder/reOrder_model.dart';

abstract class ReOrderRepository {
  Future<ReOrderModel> reOrder(
    dynamic payload,
  );
}
