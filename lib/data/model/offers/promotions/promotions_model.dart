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
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.maxDiscountAmount,
    required this.minimumOrderValue,
    required this.maximumOrderValue,
    required this.minimumItemQuantity,
    required this.maximumItemQuantity,
    required this.autoApply,
    required this.firstTimeUsersOnly,
    required this.singleUse,
    required this.stackable,
    required this.promotionType,
    required this.status,
    required this.startDate,
    required this.expiryDate,
    required this.createdDate,
    required this.updatedDate,
    required this.currentUsageCount,
    required this.totalUsageLimit,
    required this.perUserUsageLimit,
    required this.applicablePaymentMethods,
  });

  final dynamic id;
  final String? name;
  final String? code;
  final String? description;
  final String? discountType;
  final num? discountValue;
  final num? maxDiscountAmount;
  final num? minimumOrderValue;
  final num? maximumOrderValue;
  final num? minimumItemQuantity;
  final num? maximumItemQuantity;
  final bool? autoApply;
  final bool? firstTimeUsersOnly;
  final bool? singleUse;
  final bool? stackable;
  final String? promotionType;
  final String? status;
  final String? startDate;
  final String? expiryDate;
  final String? createdDate;
  final String? updatedDate;
  final num? currentUsageCount;
  final num? totalUsageLimit;
  final num? perUserUsageLimit;
  final List<dynamic> applicablePaymentMethods;

  factory PromotionContent.fromJson(Map<String, dynamic> json) {
    return PromotionContent(
      id: json["id"],
      name: json["name"],
      code: json["code"],
      description: json["description"],
      discountType: json["discountType"],
      discountValue: _toNum(json["discountValue"]),
      maxDiscountAmount: _toNum(json["maxDiscountAmount"]),
      minimumOrderValue: _toNum(json["minimumOrderValue"]),
      maximumOrderValue: _toNum(json["maximumOrderValue"]),
      minimumItemQuantity: _toNum(json["minimumItemQuantity"]),
      maximumItemQuantity: _toNum(json["maximumItemQuantity"]),
      autoApply: _toBool(json["autoApply"]),
      firstTimeUsersOnly: _toBool(json["firstTimeUsersOnly"]),
      singleUse: _toBool(json["singleUse"]),
      stackable: _toBool(json["stackable"]),
      promotionType: json["promotionType"],
      status: json["status"],
      startDate: json["startDate"],
      expiryDate: json["expiryDate"],
      createdDate: json["createdDate"],
      updatedDate: json["updatedDate"],
      currentUsageCount: _toNum(json["currentUsageCount"]),
      totalUsageLimit: _toNum(json["totalUsageLimit"]),
      perUserUsageLimit: _toNum(json["perUserUsageLimit"]),
      applicablePaymentMethods: json["applicablePaymentMethods"] == null
          ? []
          : List<dynamic>.from(json["applicablePaymentMethods"] as List),
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
