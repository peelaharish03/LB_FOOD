import 'package:local_basket/data/model/payment/deliveryModes/delivery_modes_model.dart';
import 'package:local_basket/domain/repository/payment/deliveryModes/delivery_modes_repository.dart';

class DeliveryModesUseCase {
  final DeliveryModesRepository repository;

  DeliveryModesUseCase({required this.repository});

  Future<DeliveryModesModel> call() async {
    return await repository.getDeliveryModes();
  }
}
