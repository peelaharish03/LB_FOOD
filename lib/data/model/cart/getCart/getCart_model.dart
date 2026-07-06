class GetCartModel {
  GetCartModel({
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
  final List<CartItem> items;
  final List<String>? recommendedProductIds;
  final int? version;
  final bool? storeSwitched;
  final String? previousStoreId;

  List<CartItem> get cartItems => items;
  String? get businessId => storeId;
  String? get businessName => null;
  int? get totalCount =>
      items.fold<int>(0, (sum, item) => sum + (item.quantity ?? 0));
  DateTime? get createdAt => null;
  DateTime? get updatedAt => null;
  int? get shippingAddressId => null;
  bool get selfOrder => false;

  factory GetCartModel.fromJson(Map<String, dynamic> json) {
    final cartItemsJson = json["items"] ?? json["cartItems"];

    return GetCartModel(
      id: json["id"]?.toString(),
      userId: json["userId"]?.toString(),
      storeId: (json["storeId"] ?? json["businessId"])?.toString(),
      status: json["status"],
      subTotal: _toNum(json["subTotal"]),
      totalDiscount: _toNum(json["totalDiscount"]),
      totalTax: _toNum(json["totalTax"]),
      grandTotal: _toNum(json["grandTotal"]),
      couponCode: json["couponCode"],
      notes: json["notes"],
      expiresAt: DateTime.tryParse(json["expiresAt"] ?? ""),
      items:
          cartItemsJson == null
              ? []
              : List<CartItem>.from(
                cartItemsJson.map((x) => CartItem.fromJson(x)),
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

class CartItem {
  CartItem({
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
    required this.categoryId,
    required this.price,
    required this.media,
    required this.cartId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String? id;
  final dynamic productId;
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
  final dynamic categoryId;
  final num? price;
  final List<Media> media;
  final String? cartId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json["id"]?.toString(),
      productId: json["productId"],
      productCode: json["productCode"],
      productName: json["productName"] ?? json["name"],
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
      categoryId: json["categoryId"],
      price: _toNum(json["price"] ?? json["unitPrice"] ?? json["totalPrice"]),
      media:
          json["media"] == null
              ? []
              : List<Media>.from(json["media"].map((x) => Media.fromJson(x))),
      cartId: json["cartId"]?.toString(),
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? ""),
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
    "categoryId": categoryId,
    "price": price,
    "media": media.map((x) => x.toJson()).toList(),
    "cartId": cartId,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };
}

class Media {
  Media({required this.mediaType, required this.url});

  final String? mediaType;
  final String? url;

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(mediaType: json["mediaType"], url: json["url"]);
  }

  Map<String, dynamic> toJson() => {"mediaType": mediaType, "url": url};
}

num? _toNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}
