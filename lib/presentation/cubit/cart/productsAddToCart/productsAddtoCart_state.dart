import 'package:local_basket/data/model/cart/productsAddToCart/productsAddtoCart_model.dart';

abstract class ProductsAddToCartState {}

class ProductsAddToCartInitial extends ProductsAddToCartState {}

class ProductsAddToCartLoading extends ProductsAddToCartState {}

class ProductsAddToCartSuccess extends ProductsAddToCartState {
  final ProductsAddToCartModel cartModel;

  ProductsAddToCartSuccess(this.cartModel);
}

class ProductsAddToCartFailure extends ProductsAddToCartState {
  final String message;

  ProductsAddToCartFailure(this.message);
}

class ProductsAddToCartRejected extends ProductsAddToCartState {
  final String message;
  ProductsAddToCartRejected(this.message);
}
