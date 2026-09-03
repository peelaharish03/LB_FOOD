import 'package:local_basket/data/model/payment/deliveryModes/delivery_modes_model.dart';

abstract class DeliveryModesState {}

class DeliveryModesInitial extends DeliveryModesState {}

class DeliveryModesLoading extends DeliveryModesState {}

class DeliveryModesLoaded extends DeliveryModesState {
  final DeliveryModesModel model;
  DeliveryModesLoaded({required this.model});
}

class DeliveryModesFailure extends DeliveryModesState {
  final String error;
  DeliveryModesFailure({required this.error});
}
