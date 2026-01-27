class GetNotificationsModel {
  GetNotificationsModel({
    required this.message,
    required this.status,
    required this.data,
  });

  final String? message;
  final String? status;
  final Data? data;

  factory GetNotificationsModel.fromJson(Map<String, dynamic> json) {
    return GetNotificationsModel(
      message: json["message"],
      status: json["status"],
      data: json["data"] == null ? null : Data.fromJson(json["data"]),
    );
  }
}

class Data {
  Data({
    required this.content,
    required this.pageable,
    required this.last,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
    required this.sort,
    required this.first,
    required this.numberOfElements,
    required this.empty,
  });

  final List<NotificationItem> content;
  final dynamic pageable;
  final bool? last;
  final int? totalElements;
  final int? totalPages;
  final int? size;
  final int? number;
  final List<dynamic> sort;
  final bool? first;
  final int? numberOfElements;
  final bool? empty;

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      content: (json["content"] as List<dynamic>? ?? [])
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pageable: json["pageable"],
      last: json["last"],
      totalElements: json["totalElements"],
      totalPages: json["totalPages"],
      size: json["size"],
      number: json["number"],
      sort: json["sort"] == null
          ? []
          : List<dynamic>.from(json["sort"]!.map((x) => x)),
      first: json["first"],
      numberOfElements: json["numberOfElements"],
      empty: json["empty"],
    );
  }
}

class NotificationItem {
  final int? id;
  final DateTime? creationTime;
  final String? message;
  final String? type;
  final int? userId;

  NotificationItem({
    this.id,
    this.creationTime,
    this.message,
    this.type,
    this.userId,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int?,
      creationTime: _parseDateTime(json['creationTime']),
      message: json['message'] as String?,
      type: json['type'] as String?,
      userId: json['userId'] as int?,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
