class CheckoutModel {
  CheckoutModel({
    required this.crossSellProductIds,
    required this.fraudFlagged,
    required this.orderId,
    required this.orderStatus,
    required this.paymentRedirectUrl,
    required this.paymentStatus,
    required this.razorpayKeyId,
    required this.razorpayOrderId,
    required this.totalAmount,
    required this.message,
    required this.status,
    required this.data,
  });

  final List<String> crossSellProductIds;
  final bool? fraudFlagged;
  final String? orderId;
  final String? orderStatus;
  final String? paymentRedirectUrl;
  final String? paymentStatus;
  final String? razorpayKeyId;
  final String? razorpayOrderId;
  final num? totalAmount;

  final String? message;
  final String? status;
  final CheckoutData? data;

  factory CheckoutModel.fromJson(Map<String, dynamic> json) {
    final dataJson = json["data"];
    final totalAmount = _toNum(json["totalAmount"]);

    return CheckoutModel(
      crossSellProductIds:
          json["crossSellProductIds"] == null
              ? []
              : List<String>.from(
                json["crossSellProductIds"].map((x) => x.toString()),
              ),
      fraudFlagged: json["fraudFlagged"],
      orderId: json["orderId"]?.toString(),
      orderStatus: json["orderStatus"]?.toString(),
      paymentRedirectUrl: json["paymentRedirectUrl"]?.toString(),
      paymentStatus: json["paymentStatus"]?.toString(),
      razorpayKeyId: json["razorpayKeyId"]?.toString(),
      razorpayOrderId: json["razorpayOrderId"]?.toString(),
      totalAmount: totalAmount,
      message: json["message"]?.toString(),
      status: json["status"]?.toString(),
      data:
          dataJson is Map<String, dynamic>
              ? CheckoutData.fromJson(dataJson)
              : CheckoutData(
                itemsTotal: totalAmount,
                taxTotal: _toNum(json["totalTax"]) ?? 0,
                deliveryCharge: _toNum(json["deliveryCharge"]) ?? 0,
                grandTotal: totalAmount,
              ),
    );
  }

  Map<String, dynamic> toJson() => {
    "crossSellProductIds": crossSellProductIds,
    "fraudFlagged": fraudFlagged,
    "orderId": orderId,
    "orderStatus": orderStatus,
    "paymentRedirectUrl": paymentRedirectUrl,
    "paymentStatus": paymentStatus,
    "razorpayKeyId": razorpayKeyId,
    "razorpayOrderId": razorpayOrderId,
    "totalAmount": totalAmount,
    "message": message,
    "status": status,
    "data": data?.toJson(),
  };
}

class CheckoutData {
  CheckoutData({
    required this.itemsTotal,
    required this.taxTotal,
    required this.deliveryCharge,
    required this.grandTotal,
  });

  final num? itemsTotal;
  final num? taxTotal;
  final num? deliveryCharge;
  final num? grandTotal;

  factory CheckoutData.fromJson(Map<String, dynamic> json) {
    return CheckoutData(
      itemsTotal: _toNum(json["itemsTotal"]),
      taxTotal: _toNum(json["taxTotal"]),
      deliveryCharge: _toNum(json["deliveryCharge"]),
      grandTotal: _toNum(json["grandTotal"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "itemsTotal": itemsTotal,
    "taxTotal": taxTotal,
    "deliveryCharge": deliveryCharge,
    "grandTotal": grandTotal,
  };
}

num? _toNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}
