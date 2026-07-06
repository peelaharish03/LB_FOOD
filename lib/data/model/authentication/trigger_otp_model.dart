class TriggerOtpModel {
  String? creationTime;
  String? otp;
  String? status;

  TriggerOtpModel({this.creationTime, this.otp, this.status});

  TriggerOtpModel.fromJson(Map<String, dynamic> json) {
    creationTime = json['creationTime'];
    otp = json['otp'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    return {'creationTime': creationTime, 'otp': otp, 'status': status};
  }
}
