import 'package:local_basket/data/model/address/defaultAddress/get/getDefaultAddress_model.dart';
import 'package:local_basket/domain/repository/address/defaultAddress/get/getDefaultAddress_repository.dart';

class AddressSavetoCartUseCase {
  final AddressSavetoCartRepository repository;

  AddressSavetoCartUseCase({required this.repository});

  Future<AddressSavetoCartModel> call(String addressId) {
    return repository.addressSavetoCart(addressId);
  }
}
