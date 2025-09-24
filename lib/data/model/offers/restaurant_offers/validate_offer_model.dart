class ValidateOfferModel {
  ValidateOfferModel({
    required this.message,
    required this.status,
    required this.data,
  });

  final String? message;
  final String? status;
  final String? data;

  factory ValidateOfferModel.fromJson(Map<String, dynamic> json) {
    return ValidateOfferModel(
      message: json["message"],
      status: json["status"],
      data: json["data"],
    );
  }
}
