import 'package:local_basket/data/model/cart/updateCartItems/updateCartItems_model.dart';

abstract class UpdateCartItemsState {}

class UpdateCartItemsInitial extends UpdateCartItemsState {}

class UpdateCartItemsLoading extends UpdateCartItemsState {}

class UpdateCartItemsSuccess extends UpdateCartItemsState {
  final UpdateCartItemsModel updatedItem;

  UpdateCartItemsSuccess(this.updatedItem);
}

class UpdateCartItemsFailure extends UpdateCartItemsState {
  final String error;

  /// True when the failed call was a background sync (e.g. persisting the
  /// payment method) — the screen shouldn't pop an error for it.
  final bool silent;

  UpdateCartItemsFailure(this.error, {this.silent = false});
}
