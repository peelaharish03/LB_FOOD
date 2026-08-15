class JoinPoolModel {
  JoinPoolModel({this.success, this.message, this.data});

  final bool? success;
  final String? message;
  final dynamic data;

  factory JoinPoolModel.fromJson(Map<String, dynamic> json) {
    return JoinPoolModel(
      success: json["success"] as bool?,
      message: json["message"]?.toString(),
      data: json["data"],
    );
  }
}
