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
    final rawData = json["data"];
    final dataJson = rawData is Map<String, dynamic> ? rawData : null;
    final source = dataJson ?? json;
    final totalAmount =
        _toNum(_read(source, ["totalAmount", "amount", "grandTotal"])) ??
        _toNum(_read(json, ["totalAmount", "amount", "grandTotal"]));

    return CheckoutModel(
      crossSellProductIds: _toStringList(
        _read(source, ["crossSellProductIds"]),
      ),
      fraudFlagged: _toBool(_read(source, ["fraudFlagged"])),
      orderId: _read(source, ["orderId", "order_id", "id"])?.toString(),
      orderStatus: _read(source, ["orderStatus", "order_status"])?.toString(),
      paymentRedirectUrl:
          _read(source, [
            "paymentRedirectUrl",
            "payment_redirect_url",
          ])?.toString(),
      paymentStatus:
          _read(source, ["paymentStatus", "payment_status"])?.toString(),
      razorpayKeyId:
          _read(source, [
            "razorpayKeyId",
            "razorpay_key_id",
            "keyId",
            "key_id",
          ])?.toString(),
      razorpayOrderId:
          _read(source, [
            "razorpayOrderId",
            "razorpay_order_id",
            "rzpOrderId",
            "order_id",
          ])?.toString(),
      totalAmount: totalAmount,
      message: json["message"]?.toString(),
      status: json["status"]?.toString(),
      data: CheckoutData.fromJson(source, fallbackTotal: totalAmount),
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

  factory CheckoutData.fromJson(
    Map<String, dynamic> json, {
    num? fallbackTotal,
  }) {
    return CheckoutData(
      itemsTotal: _toNum(
        _read(json, ["itemsTotal", "items_total", "subTotal"]),
      ),
      taxTotal: _toNum(_read(json, ["taxTotal", "tax_total", "totalTax"])),
      deliveryCharge: _toNum(
        _read(json, ["deliveryCharge", "delivery_charge"]),
      ),
      grandTotal:
          _toNum(_read(json, ["grandTotal", "grand_total", "totalAmount"])) ??
          fallbackTotal,
    );
  }

  Map<String, dynamic> toJson() => {
    "itemsTotal": itemsTotal,
    "taxTotal": taxTotal,
    "deliveryCharge": deliveryCharge,
    "grandTotal": grandTotal,
  };
}

dynamic _read(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) return json[key];
  }
  return null;
}

List<String> _toStringList(dynamic value) {
  if (value is Iterable) return value.map((x) => x.toString()).toList();
  return [];
}

bool? _toBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  final text = value.toString().toLowerCase();
  if (text == 'true') return true;
  if (text == 'false') return false;
  return null;
}

num? _toNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}
