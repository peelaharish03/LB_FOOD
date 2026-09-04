import 'package:local_basket/data/model/address/updateAddress/updateAddress_model.dart';
import 'package:local_basket/domain/repository/address/updateAddress/updateAddress_repository.dart';

class UpdateAddressUseCase {
  final UpdateAddressRepository repository;

  UpdateAddressUseCase({required this.repository});

  Future<UpdateAddressModel> call(
    String addressId,
    Map<String, dynamic> payload,
  ) {
    return repository.updateAddress(addressId, payload);
  }
}
