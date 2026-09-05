import 'package:flutter/foundation.dart';
import 'package:local_basket/data/datasource/address/getAddress/getAddress_dataSource.dart';
import 'package:local_basket/data/model/address/getAddress/getAddress_model.dart';
import 'package:local_basket/domain/repository/address/getAddress/getAddress_repository.dart';

class GetAddressRepositoryImpl implements GetAddressRepository {
  final GetAddressRemoteDataSource remoteDataSource;

  GetAddressRepositoryImpl({required this.remoteDataSource});

  static const String _tag = '[GetAddress][Repository]';

  @override
  Future<GetAddressModel> getAddress() async {
    debugPrint('$_tag ➡️ getAddress() → calling remote data source');
    try {
      final result = await remoteDataSource.getAddress();
      debugPrint(
        '$_tag ✅ getAddress() → ${result.content.length} address(es) returned',
      );
      return result;
    } catch (e) {
      debugPrint('$_tag ❌ getAddress() failed: $e');
      rethrow;
    }
  }
}
