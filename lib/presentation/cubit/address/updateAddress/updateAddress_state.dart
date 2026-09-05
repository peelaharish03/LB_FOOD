import 'package:local_basket/data/model/address/updateAddress/updateAddress_model.dart';

abstract class UpdateAddressState {}

class UpdateAddressInitial extends UpdateAddressState {}

class UpdateAddressLoading extends UpdateAddressState {}

class UpdateAddressSuccess extends UpdateAddressState {
  final UpdateAddressModel response;

  UpdateAddressSuccess(this.response);
}

class UpdateAddressFailure extends UpdateAddressState {
  final String error;

  UpdateAddressFailure(this.error);
}
