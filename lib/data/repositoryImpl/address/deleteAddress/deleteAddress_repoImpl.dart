import 'package:local_basket/data/datasource/address/deleteAddress/deleteAddress_dataSource.dart';
import 'package:local_basket/data/model/address/deleteAddress/deleteAddress_model.dart';
import 'package:local_basket/domain/repository/address/deleteAddress/deleteAddress_repository.dart';

class DeleteAddressRepositoryImpl implements DeleteAddressRepository {
  final DeleteAddressRemoteDataSource remoteDataSource;

  DeleteAddressRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DeleteAddressModel> deleteAddress(String addressId) async {
    return await remoteDataSource.DeleteAddress(addressId);
  }
}
