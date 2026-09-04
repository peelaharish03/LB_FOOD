import 'package:local_basket/data/datasource/address/updateAddress/updateAddress_dataSource.dart';
import 'package:local_basket/data/model/address/updateAddress/updateAddress_model.dart';
import 'package:local_basket/domain/repository/address/updateAddress/updateAddress_repository.dart';

class UpdateAddressRepositoryImpl implements UpdateAddressRepository {
  final UpdateAddressRemoteDataSource remoteDataSource;

  UpdateAddressRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UpdateAddressModel> updateAddress(
    String addressId,
    Map<String, dynamic> payload,
  ) {
    return remoteDataSource.updateAddress(addressId, payload);
  }
}
