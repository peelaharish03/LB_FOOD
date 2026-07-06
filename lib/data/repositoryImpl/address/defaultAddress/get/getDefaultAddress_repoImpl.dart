import 'package:local_basket/data/datasource/address/defaultAddress/get/getDefaultAddress_dataSource.dart';
import 'package:local_basket/data/model/address/defaultAddress/get/getDefaultAddress_model.dart';
import 'package:local_basket/domain/repository/address/defaultAddress/get/getDefaultAddress_repository.dart';

class AddressSavetoCartRepositoryImpl implements AddressSavetoCartRepository {
  final AddressSavetoCartRemoteDataSource remoteDataSource;

  AddressSavetoCartRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AddressSavetoCartModel> addressSavetoCart(String addressId) {
    return remoteDataSource.addressSavetoCart(addressId);
  }
}
