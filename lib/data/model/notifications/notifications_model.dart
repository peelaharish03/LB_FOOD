class GetNotificationsModel {
    GetNotificationsModel({
        required this.totalItems,
        required this.data,
        required this.pageNo,
        required this.totalPages,
        required this.pageSize,
        required this.currentPage,
    });

    final num? totalItems;
    final List<Datum> data;
    final num? pageNo;
    final num? totalPages;
    final num? pageSize;
    final num? currentPage;

    factory GetNotificationsModel.fromJson(Map<String, dynamic> json){ 
        return GetNotificationsModel(
            totalItems: json["totalItems"],
            data: json["data"] == null ? [] : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
            pageNo: json["pageNo"],
            totalPages: json["totalPages"],
            pageSize: json["pageSize"],
            currentPage: json["currentPage"],
        );
    }

}

class Datum {
    Datum({
        required this.id,
        required this.creationTime,
        required this.message,
        required this.type,
        required this.userId,
    });

    final num? id;
    final DateTime? creationTime;
    final String? message;
    final String? type;
    final num? userId;

    factory Datum.fromJson(Map<String, dynamic> json){ 
        return Datum(
            id: json["id"],
            creationTime: DateTime.tryParse(json["creationTime"] ?? ""),
            message: json["message"],
            type: json["type"],
            userId: json["userId"],
        );
    }

}
