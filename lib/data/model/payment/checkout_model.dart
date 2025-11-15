class CheckoutModel {
  CheckoutModel({
    required this.message,
    required this.status,
    required this.data,
  });

  final String? message;
  final String? status;
  final Data? data;

  factory CheckoutModel.fromJson(Map<String, dynamic> json) {
    return CheckoutModel(
      message: json["message"],
      status: json["status"],
      data: json["data"] == null ? null : Data.fromJson(json["data"]),
    );
  }
}

class Data {
  Data({
    required this.itemsTotal,
    required this.taxTotal,
    required this.deliveryCharge,
    required this.grandTotal,
  });

  final num? itemsTotal;
  final num? taxTotal;
  final num? deliveryCharge;
  final num? grandTotal;

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      itemsTotal: json["itemsTotal"],
      taxTotal: json["taxTotal"],
      deliveryCharge: json["deliveryCharge"],
      grandTotal: json["grandTotal"],
    );
  }
}
