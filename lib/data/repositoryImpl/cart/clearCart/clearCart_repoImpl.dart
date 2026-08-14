import 'package:local_basket/data/datasource/cart/clearCart/clearCart_dataSource.dart';
import 'package:local_basket/data/model/cart/clearCart/clearCart_model.dart';
import 'package:local_basket/domain/repository/cart/clearCart/clearCart_repository.dart';

class ClearCartRepositoryImpl implements ClearCartRepository {
  final ClearCartRemoteDataSource remoteDataSource;

  ClearCartRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ClearCartModel> clearCart(String cartId) {
    return remoteDataSource.clearCart(cartId);
  }
}
