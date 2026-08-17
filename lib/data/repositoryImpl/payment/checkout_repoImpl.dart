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

  @override
  Future<CheckoutModel> initiateCheckout(Map<String, dynamic> payload) async {
    return await remoteDataSource.initiateCheckout(payload);
  }

  @override
  Future<CheckoutModel> checkoutCod(Map<String, dynamic> payload) async {
    return await remoteDataSource.checkoutCod(payload);
  }

  @override
  Future<CheckoutModel> verifyPayment(Map<String, dynamic> payload) async {
    return await remoteDataSource.verifyPayment(payload);
  }
}
