import 'package:local_basket/data/model/address/defaultAddress/post/defaultAddress_model.dart';

abstract class DefaultAddressRepository {
  Future<DefaultAddressModel> setDefaultAddress(String addressId);
}
