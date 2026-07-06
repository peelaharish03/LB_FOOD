class ProductsAddToCartModel {
  ProductsAddToCartModel({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.status,
    required this.subTotal,
    required this.totalDiscount,
    required this.totalTax,
    required this.grandTotal,
    required this.couponCode,
    required this.notes,
    required this.expiresAt,
    required this.items,
    required this.recommendedProductIds,
    required this.version,
    required this.storeSwitched,
    required this.previousStoreId,
  });

  final String? id;
  final String? userId;
  final String? storeId;
  final String? status;
  final num? subTotal;
  final num? totalDiscount;
  final num? totalTax;
  final num? grandTotal;
  final String? couponCode;
  final String? notes;
  final DateTime? expiresAt;
  final List<ProductsAddToCartItem> items;
  final List<String>? recommendedProductIds;
  final int? version;
  final bool? storeSwitched;
  final String? previousStoreId;

  factory ProductsAddToCartModel.fromJson(Map<String, dynamic> json) {
    return ProductsAddToCartModel(
      id: json["id"]?.toString(),
      userId: json["userId"]?.toString(),
      storeId: json["storeId"]?.toString(),
      status: json["status"],
      subTotal: _toNum(json["subTotal"]),
      totalDiscount: _toNum(json["totalDiscount"]),
      totalTax: _toNum(json["totalTax"]),
      grandTotal: _toNum(json["grandTotal"]),
      couponCode: json["couponCode"],
      notes: json["notes"],
      expiresAt: DateTime.tryParse(json["expiresAt"] ?? ""),
      items:
          json["items"] == null
              ? []
              : List<ProductsAddToCartItem>.from(
                json["items"].map((x) => ProductsAddToCartItem.fromJson(x)),
              ),
      recommendedProductIds:
          json["recommendedProductIds"] == null
              ? null
              : List<String>.from(
                json["recommendedProductIds"].map((x) => x.toString()),
              ),
      version: json["version"],
      storeSwitched: json["storeSwitched"],
      previousStoreId: json["previousStoreId"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "userId": userId,
    "storeId": storeId,
    "status": status,
    "subTotal": subTotal,
    "totalDiscount": totalDiscount,
    "totalTax": totalTax,
    "grandTotal": grandTotal,
    "couponCode": couponCode,
    "notes": notes,
    "expiresAt": expiresAt?.toIso8601String(),
    "items": items.map((x) => x.toJson()).toList(),
    "recommendedProductIds": recommendedProductIds,
    "version": version,
    "storeSwitched": storeSwitched,
    "previousStoreId": previousStoreId,
  };
}

class ProductsAddToCartItem {
  ProductsAddToCartItem({
    required this.id,
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.skuId,
    required this.quantity,
    required this.unitPrice,
    required this.discountPrice,
    required this.taxAmount,
    required this.totalPrice,
    required this.gift,
    required this.giftMessage,
    required this.appointment,
    required this.recommendedProductIds,
  });

  final String? id;
  final String? productId;
  final String? productCode;
  final String? productName;
  final String? skuId;
  final int? quantity;
  final num? unitPrice;
  final num? discountPrice;
  final num? taxAmount;
  final num? totalPrice;
  final bool? gift;
  final String? giftMessage;
  final dynamic appointment;
  final List<String>? recommendedProductIds;

  factory ProductsAddToCartItem.fromJson(Map<String, dynamic> json) {
    return ProductsAddToCartItem(
      id: json["id"]?.toString(),
      productId: json["productId"]?.toString(),
      productCode: json["productCode"],
      productName: json["productName"],
      skuId: json["skuId"]?.toString(),
      quantity: json["quantity"],
      unitPrice: _toNum(json["unitPrice"]),
      discountPrice: _toNum(json["discountPrice"]),
      taxAmount: _toNum(json["taxAmount"]),
      totalPrice: _toNum(json["totalPrice"]),
      gift: json["gift"],
      giftMessage: json["giftMessage"],
      appointment: json["appointment"],
      recommendedProductIds:
          json["recommendedProductIds"] == null
              ? null
              : List<String>.from(
                json["recommendedProductIds"].map((x) => x.toString()),
              ),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "productId": productId,
    "productCode": productCode,
    "productName": productName,
    "skuId": skuId,
    "quantity": quantity,
    "unitPrice": unitPrice,
    "discountPrice": discountPrice,
    "taxAmount": taxAmount,
    "totalPrice": totalPrice,
    "gift": gift,
    "giftMessage": giftMessage,
    "appointment": appointment,
    "recommendedProductIds": recommendedProductIds,
  };
}

num? _toNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}
