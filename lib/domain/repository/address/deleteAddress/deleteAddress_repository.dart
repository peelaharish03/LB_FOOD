import 'package:local_basket/data/model/address/deleteAddress/deleteAddress_model.dart';

abstract class DeleteAddressRepository {
  Future<DeleteAddressModel> deleteAddress(String addressId);
}
