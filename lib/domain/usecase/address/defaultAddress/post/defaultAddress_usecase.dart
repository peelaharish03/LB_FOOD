import 'package:local_basket/data/model/address/defaultAddress/post/defaultAddress_model.dart';
import 'package:local_basket/domain/repository/address/defaultAddress/post/defaultAddress_repository.dart';

class DefaultAddressUseCase {
  final DefaultAddressRepository repository;

  DefaultAddressUseCase({required this.repository});

  Future<DefaultAddressModel> call(String addressId) {
    return repository.setDefaultAddress(addressId);
  }
}
