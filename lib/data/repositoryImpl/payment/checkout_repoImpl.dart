import 'package:local_basket/data/datasource/payment/checkout_datasource.dart';
import 'package:local_basket/data/model/payment/checkout_model.dart';
import 'package:local_basket/domain/repository/payment/checkout_repository.dart';

class CheckoutRepositoryImpl implements CheckoutRepository {
  final CheckoutRemoteDataSource remoteDataSource;

  CheckoutRepositoryImpl({required this.remoteDataSource});

  @override
  Future<CheckoutModel> checkout(Map<String, dynamic> payload) async {
    return await remoteDataSource.checkout(payload);
  }
}
