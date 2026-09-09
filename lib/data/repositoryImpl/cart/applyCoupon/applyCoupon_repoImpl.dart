import 'package:local_basket/data/datasource/cart/applyCoupon/applyCoupon_dataSource.dart';
import 'package:local_basket/domain/repository/cart/applyCoupon/applyCoupon_repository.dart';

class ApplyCouponRepositoryImpl implements ApplyCouponRepository {
  final ApplyCouponRemoteDataSource remoteDataSource;

  ApplyCouponRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> applyCoupon(String cartId, String code) {
    return remoteDataSource.applyCoupon(cartId, code);
  }

  @override
  Future<void> removeCoupon(String cartId, String code) {
    return remoteDataSource.removeCoupon(cartId, code);
  }
}
