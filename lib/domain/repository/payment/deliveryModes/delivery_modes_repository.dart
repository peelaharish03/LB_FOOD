import 'package:local_basket/data/model/payment/deliveryModes/delivery_modes_model.dart';

abstract class DeliveryModesRepository {
  Future<DeliveryModesModel> getDeliveryModes();
}
