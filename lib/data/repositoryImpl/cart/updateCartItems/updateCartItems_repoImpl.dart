import 'package:local_basket/data/datasource/cart/updateCartItems/updateCartItems_dataSource.dart';
import 'package:local_basket/data/model/cart/updateCartItems/updateCartItems_model.dart';
import 'package:local_basket/domain/repository/cart/updateCartItems/updateCartItems_repository.dart';

class UpdateCartItemsRepositoryImpl implements UpdateCartItemsRepository {
  final UpdateCartItemsRemoteDataSource remoteDataSource;

  UpdateCartItemsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UpdateCartItemsModel> updateCartItems(
    Map<String, dynamic> payload,
    String cartId,
    String itemId,
  ) {
    return remoteDataSource.updateCartItems(payload, cartId, itemId);
  }
}
