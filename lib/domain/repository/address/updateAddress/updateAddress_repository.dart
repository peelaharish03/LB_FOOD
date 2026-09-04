import 'package:local_basket/data/model/address/updateAddress/updateAddress_model.dart';

abstract class UpdateAddressRepository {
  Future<UpdateAddressModel> updateAddress(
    String addressId,
    Map<String, dynamic> payload,
  );
}
