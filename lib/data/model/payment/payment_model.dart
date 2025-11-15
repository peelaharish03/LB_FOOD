class PaymentModel {
  PaymentModel({
    required this.message,
    required this.status,
  });

  final String? message;
  final String? status;

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      message: json["message"],
      status: json["status"],
    );
  }
}

class PaymentStausModel {
  String? message;
  String? status;

  PaymentStausModel({this.message, this.status});

  PaymentStausModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    data['status'] = status;
    return data;
  }
}

class PaymentRefundModel {
  String? message;
  String? status;

  PaymentRefundModel({this.message, this.status});

  PaymentRefundModel.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    data['status'] = status;
    return data;
  }
}
