class GetCartModel {
  GetCartModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.selfOrder,
    required this.cartItems,
    required this.businessId,
    required this.businessName,
    required this.notes,
    required this.totalCount,
    required this.createdAt,
    required this.updatedAt,
    required this.shippingAddressId,
  });

  final int? id;
  final int? userId;
  final String? status;
  final bool? selfOrder;
  final List<CartItem> cartItems;
  final int? businessId;
  final String? businessName;
  final String? notes;
  final int? totalCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? shippingAddressId;

  factory GetCartModel.fromJson(Map<String, dynamic> json) {
    return GetCartModel(
      id: json["id"],
      userId: json["userId"],
      status: json["status"],
      selfOrder: json["selfOrder"],
      cartItems: json["cartItems"] == null
          ? []
          : List<CartItem>.from(
              json["cartItems"]!.map((x) => CartItem.fromJson(x))),
      businessId: json["businessId"],
      businessName: json["businessName"],
      notes: json["notes"],
      totalCount: json["totalCount"],
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? ""),
      shippingAddressId: json["shippingAddressId"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "userId": userId,
        "status": status,
        "selfOrder": selfOrder,
        "cartItems": cartItems.map((x) => x.toJson()).toList(),
        "businessId": businessId,
        "businessName": businessName,
        "notes": notes,
        "totalCount": totalCount,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "shippingAddressId": shippingAddressId,
      };
}

class CartItem {
  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.categoryId,
    required this.price,
    required this.media,
    required this.cartId,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int? productId;
  final String? productName;
  final int? quantity;
  final int? categoryId;
  final double? price;
  final List<Media> media;
  final int? cartId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json["id"],
      productId: json["productId"],
      productName: json["productName"],
      quantity: json["quantity"],
      categoryId: json["categoryId"],
      price: (json["price"] is int)
          ? (json["price"] as int).toDouble()
          : json["price"]?.toDouble(),
      media: json["media"] == null
          ? []
          : List<Media>.from(json["media"]!.map((x) => Media.fromJson(x))),
      cartId: json["cartId"],
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? ""),
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "productId": productId,
        "productName": productName,
        "quantity": quantity,
        "categoryId": categoryId,
        "price": price,
        "media": media.map((x) => x.toJson()).toList(),
        "cartId": cartId,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
      };
}

class Media {
  Media({
    required this.mediaType,
    required this.url,
  });

  final String? mediaType;
  final String? url;

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      mediaType: json["mediaType"],
      url: json["url"],
    );
  }

  Map<String, dynamic> toJson() => {
        "mediaType": mediaType,
        "url": url,
      };
}
