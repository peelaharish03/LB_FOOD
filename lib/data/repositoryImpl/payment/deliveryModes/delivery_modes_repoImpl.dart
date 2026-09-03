import 'package:local_basket/data/datasource/payment/deliveryModes/delivery_modes_datasource.dart';
import 'package:local_basket/data/model/payment/deliveryModes/delivery_modes_model.dart';
import 'package:local_basket/domain/repository/payment/deliveryModes/delivery_modes_repository.dart';

class DeliveryModesRepositoryImpl implements DeliveryModesRepository {
  final DeliveryModesRemoteDataSource remoteDataSource;

  DeliveryModesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DeliveryModesModel> getDeliveryModes() async {
    return await remoteDataSource.getDeliveryModes();
  }
}
