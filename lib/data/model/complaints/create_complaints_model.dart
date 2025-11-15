class CreateComplaintModel {
  CreateComplaintModel({
    required this.message,
    required this.status,
    required this.data,
  });

  final String? message;
  final String? status;
  final Data? data;

  factory CreateComplaintModel.fromJson(Map<String, dynamic> json) {
    return CreateComplaintModel(
      message: json["message"],
      status: json["status"],
      data: json["data"] == null ? null : Data.fromJson(json["data"]),
    );
  }
}

class Data {
  Data({
    required this.id,
    required this.title,
    required this.description,
    required this.createdDt,
    required this.createdBy,
    required this.status,
    required this.complaintType,
    required this.assignedTo,
    required this.assignedOn,
    required this.orderId,
    required this.businessId,
  });

  final int? id;
  final String? title;
  final String? description;
  final DateTime? createdDt;
  final int? createdBy;
  final String? status;
  final String? complaintType;
  final dynamic assignedTo;
  final dynamic assignedOn;
  final String? orderId;
  final dynamic businessId;

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      id: json["id"],
      title: json["title"],
      description: json["description"],
      createdDt: DateTime.tryParse(json["createdDt"] ?? ""),
      createdBy: json["createdBy"],
      status: json["status"],
      complaintType: json["complaintType"],
      assignedTo: json["assignedTo"],
      assignedOn: json["assignedOn"],
      orderId: json["orderId"],
      businessId: json["businessId"],
    );
  }
}
