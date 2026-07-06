import 'package:local_basket/data/model/address/deleteAddress/deleteAddress_model.dart';
import 'package:local_basket/domain/repository/address/deleteAddress/deleteAddress_repository.dart';

class DeleteAddressUseCase {
  final DeleteAddressRepository repository;

  DeleteAddressUseCase({required this.repository});

  Future<DeleteAddressModel> execute(String addressId) async {
    return await repository.deleteAddress(addressId);
  }
}
