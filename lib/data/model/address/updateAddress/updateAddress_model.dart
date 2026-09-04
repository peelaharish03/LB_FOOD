class UpdateAddressModel {
  UpdateAddressModel({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool? success;
  final String? message;
  final dynamic data;

  factory UpdateAddressModel.fromJson(dynamic json) {
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      return UpdateAddressModel(
        success: map["success"] is bool ? map["success"] as bool : null,
        message: map["message"]?.toString(),
        data: map["data"] ?? map["address"] ?? map,
      );
    }
    return UpdateAddressModel(success: null, message: null, data: json);
  }
}
