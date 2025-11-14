class RatingReviewModel {
  RatingReviewModel({
    required this.message,
    required this.status,
    required this.data,
  });

  final String? message;
  final String? status;
  final Data? data;

  factory RatingReviewModel.fromJson(Map<String, dynamic> json) {
    return RatingReviewModel(
      message: json["message"],
      status: json["status"],
      data: json["data"] == null ? null : Data.fromJson(json["data"]),
    );
  }
}

class Data {
  Data({
    required this.userId,
    required this.productId,
    required this.businessId,
    required this.type,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final int? userId;
  final int? productId;
  final int? businessId;
  final String? type;
  final int? rating;
  final String? comment;
  final DateTime? createdAt;

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      userId: json["userId"],
      productId: json["productId"],
      businessId: json["businessId"],
      type: json["type"],
      rating: json["rating"],
      comment: json["comment"],
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
    );
  }
}
