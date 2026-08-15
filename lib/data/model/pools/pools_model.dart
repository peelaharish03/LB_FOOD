class PoolsModel {
  PoolsModel({required this.content, required this.page});

  final List<PoolItem> content;
  final PoolPageInfo? page;

  factory PoolsModel.fromJson(Map<String, dynamic> json) {
    return PoolsModel(
      content: (json["content"] as List<dynamic>? ?? [])
          .map((e) => PoolItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: json["page"] == null
          ? null
          : PoolPageInfo.fromJson(json["page"]),
    );
  }
}

class PoolPageInfo {
  PoolPageInfo({
    required this.size,
    required this.number,
    required this.totalElements,
    required this.totalPages,
  });

  final int? size;
  final int? number;
  final int? totalElements;
  final int? totalPages;

  factory PoolPageInfo.fromJson(Map<String, dynamic> json) {
    return PoolPageInfo(
      size: json["size"],
      number: json["number"],
      totalElements: json["totalElements"],
      totalPages: json["totalPages"],
    );
  }
}

enum PoolStatus { upcoming, active, completed }

class PoolItem {
  final String? b2bUnitId;
  final String? date;
  final String? description;
  final String? endTime;
  final String? id;
  final bool? joinedByCurrentUser;
  final String? name;
  final int? participantCount;
  final String? startTime;
  final String? status;
  final String? winnerSelectedAt;
  final String? winnerUserId;

  PoolItem({
    this.b2bUnitId,
    this.date,
    this.description,
    this.endTime,
    this.id,
    this.joinedByCurrentUser,
    this.name,
    this.participantCount,
    this.startTime,
    this.status,
    this.winnerSelectedAt,
    this.winnerUserId,
  });

  factory PoolItem.fromJson(Map<String, dynamic> json) {
    return PoolItem(
      b2bUnitId: json['b2bUnitId'] as String?,
      date: json['date'] as String?,
      description: json['description'] as String?,
      endTime: json['endTime'] as String?,
      id: json['id'] as String?,
      joinedByCurrentUser: json['joinedByCurrentUser'] as bool?,
      name: json['name'] as String?,
      participantCount: json['participantCount'] as int?,
      startTime: json['startTime'] as String?,
      status: json['status'] as String?,
      winnerSelectedAt: json['winnerSelectedAt'] as String?,
      winnerUserId: json['winnerUserId'] as String?,
    );
  }

  DateTime? get startDateTime => _combine(date, startTime);
  DateTime? get endDateTime => _combine(date, endTime);

  static DateTime? _combine(String? date, String? time) {
    if (date == null || time == null) return null;
    final dateParts = date.split('-');
    final timeParts = time.split(':');
    if (dateParts.length < 3 || timeParts.length < 2) return null;
    try {
      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (_) {
      return null;
    }
  }

  PoolStatus statusAt(DateTime now) {
    final start = startDateTime;
    final end = endDateTime;
    if (start == null || end == null) return PoolStatus.upcoming;
    if (now.isBefore(start)) return PoolStatus.upcoming;
    if (now.isAfter(end)) return PoolStatus.completed;
    return PoolStatus.active;
  }
}
