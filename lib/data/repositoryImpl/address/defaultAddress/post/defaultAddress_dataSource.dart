import 'package:local_basket/data/datasource/address/defaultAddress/post/defaultAddress_dataSource.dart';
import 'package:local_basket/data/model/address/defaultAddress/post/defaultAddress_model.dart';
import 'package:local_basket/domain/repository/address/defaultAddress/post/defaultAddress_repository.dart';

class DefaultAddressRepositoryImpl implements DefaultAddressRepository {
  final DefaultAddressRemoteDataSource remoteDataSource;

  DefaultAddressRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DefaultAddressModel> setDefaultAddress(String addressId) {
    return remoteDataSource.defaultAddress(addressId);
  }
}
