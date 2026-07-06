class CreateCartModel {
  CreateCartModel({
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
  final List<dynamic> items;
  final List<String> recommendedProductIds;
  final int? version;
  final bool? storeSwitched;
  final String? previousStoreId;

  factory CreateCartModel.fromJson(Map<String, dynamic> json) {
    return CreateCartModel(
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
      items: json["items"] == null ? [] : List<dynamic>.from(json["items"]),
      recommendedProductIds:
          json["recommendedProductIds"] == null
              ? []
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
    "items": items,
    "recommendedProductIds": recommendedProductIds,
    "version": version,
    "storeSwitched": storeSwitched,
    "previousStoreId": previousStoreId,
  };
}

num? _toNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}
