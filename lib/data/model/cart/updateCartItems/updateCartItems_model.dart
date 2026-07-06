import 'package:local_basket/data/model/cart/getCart/getCart_model.dart';

class UpdateCartItemsModel extends GetCartModel {
  UpdateCartItemsModel({
    required super.id,
    required super.userId,
    required super.storeId,
    required super.status,
    required super.subTotal,
    required super.totalDiscount,
    required super.totalTax,
    required super.grandTotal,
    required super.couponCode,
    required super.notes,
    required super.expiresAt,
    required super.items,
    required super.recommendedProductIds,
    required super.version,
    required super.storeSwitched,
    required super.previousStoreId,
  });

  factory UpdateCartItemsModel.fromJson(Map<String, dynamic> json) {
    final model = GetCartModel.fromJson(json);
    return UpdateCartItemsModel(
      id: model.id,
      userId: model.userId,
      storeId: model.storeId,
      status: model.status,
      subTotal: model.subTotal,
      totalDiscount: model.totalDiscount,
      totalTax: model.totalTax,
      grandTotal: model.grandTotal,
      couponCode: model.couponCode,
      notes: model.notes,
      expiresAt: model.expiresAt,
      items: model.items,
      recommendedProductIds: model.recommendedProductIds,
      version: model.version,
      storeSwitched: model.storeSwitched,
      previousStoreId: model.previousStoreId,
    );
  }
}
