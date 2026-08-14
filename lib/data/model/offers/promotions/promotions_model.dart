class PromotionsModel {
  PromotionsModel({
    required this.content,
    required this.page,
  });

  final List<PromotionContent> content;
  final PromotionsPage? page;

  factory PromotionsModel.fromJson(Map<String, dynamic> json) {
    final dynamic data = json["data"];
    Map<String, dynamic> page;
    if (data is List) {
      page = {"content": data};
    } else if (data is Map<String, dynamic>) {
      page = data;
    } else {
      page = json;
    }
    return PromotionsModel(
      content: page["content"] == null
          ? []
          : _parseContent(page["content"] as List),
      page: page["page"] == null ? null : PromotionsPage.fromJson(page["page"]),
    );
  }

  static List<PromotionContent> _parseContent(List dynamicList) {
    final List<PromotionContent> result = [];
    for (final item in dynamicList) {
      try {
        if (item is Map<String, dynamic>) {
          result.add(PromotionContent.fromJson(item));
        }
      } catch (_) {}
    }
    return result;
  }
}

class PromotionContent {
  PromotionContent({
    required this.actionJson,
    required this.code,
    required this.conditionTreeJson,
    required this.createdDate,
    required this.customerFacingLabel,
    required this.endsAt,
    required this.exclusive,
    required this.id,
    required this.internalDescription,
    required this.maxRedemptions,
    required this.maxRedemptionsPerCustomer,
    required this.name,
    required this.priority,
    required this.promoType,
    required this.startsAt,
    required this.status,
    required this.updatedDate,
    required this.usedCount,
    required this.version,
  });

  final dynamic actionJson;
  final String? code;
  final dynamic conditionTreeJson;
  final String? createdDate;
  final String? customerFacingLabel;
  final String? endsAt;
  final bool? exclusive;
  final dynamic id;
  final String? internalDescription;
  final num? maxRedemptions;
  final num? maxRedemptionsPerCustomer;
  final String? name;
  final num? priority;
  final String? promoType;
  final String? startsAt;
  final String? status;
  final String? updatedDate;
  final num? usedCount;
  final num? version;

  factory PromotionContent.fromJson(Map<String, dynamic> json) {
    return PromotionContent(
      actionJson: json["actionJson"],
      code: json["code"],
      conditionTreeJson: json["conditionTreeJson"],
      createdDate: json["createdDate"],
      customerFacingLabel: json["customerFacingLabel"],
      endsAt: json["endsAt"],
      exclusive: _toBool(json["exclusive"]),
      id: json["id"],
      internalDescription: json["internalDescription"],
      maxRedemptions: _toNum(json["maxRedemptions"]),
      maxRedemptionsPerCustomer: _toNum(json["maxRedemptionsPerCustomer"]),
      name: json["name"],
      priority: _toNum(json["priority"]),
      promoType: json["promoType"],
      startsAt: json["startsAt"],
      status: json["status"],
      updatedDate: json["updatedDate"],
      usedCount: _toNum(json["usedCount"]),
      version: _toNum(json["version"]),
    );
  }
}

num? _toNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}

bool? _toBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value.toString().toLowerCase() == 'true';
}

class PromotionsPage {
  PromotionsPage({
    required this.size,
    required this.number,
    required this.totalElements,
    required this.totalPages,
  });

  final num? size;
  final num? number;
  final num? totalElements;
  final num? totalPages;

  factory PromotionsPage.fromJson(Map<String, dynamic> json) {
    return PromotionsPage(
      size: json["size"],
      number: json["number"],
      totalElements: json["totalElements"],
      totalPages: json["totalPages"],
    );
  }
}
