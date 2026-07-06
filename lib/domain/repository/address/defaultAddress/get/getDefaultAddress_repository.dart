import 'package:local_basket/data/model/address/defaultAddress/get/getDefaultAddress_model.dart';

abstract class AddressSavetoCartRepository {
  Future<AddressSavetoCartModel> addressSavetoCart(String addressId);
}
