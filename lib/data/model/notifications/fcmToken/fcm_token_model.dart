class FcmTokenModel {
  FcmTokenModel({
    this.fcmToken,
    this.deviceType,
    this.lastTokenUpdate,
    this.hasToken,
    this.status,
    this.message,
  });

  final String? fcmToken;
  final String? deviceType;
  final String? lastTokenUpdate;
  final bool? hasToken;
  final String? status;
  final String? message;

  factory FcmTokenModel.fromJson(Map<String, dynamic> json) {
    return FcmTokenModel(
      fcmToken: json["fcmToken"],
      deviceType: json["deviceType"],
      lastTokenUpdate: json["lastTokenUpdate"],
      hasToken: json["hasToken"],
      status: json["status"],
      message: json["message"],
    );
  }
}
