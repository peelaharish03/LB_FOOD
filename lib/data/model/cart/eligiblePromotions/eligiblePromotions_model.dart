class EligiblePromotionsModel {
  EligiblePromotionsModel({required this.promotions, this.status, this.message});

  final List<EligiblePromotion> promotions;
  final String? status;
  final String? message;

  factory EligiblePromotionsModel.fromJson(Map<String, dynamic> json) {
    return EligiblePromotionsModel(
      promotions: _parsePromotions(_extractList(json)),
      status: json["status"]?.toString(),
      message: json["message"]?.toString(),
    );
  }

  static List<dynamic> _extractList(Map<String, dynamic> json) {
    final data = json["data"];
    if (data is List) return data;
    if (data is Map<String, dynamic> && data["content"] is List) {
      return data["content"] as List;
    }
    if (json["content"] is List) return json["content"] as List;
    if (json["promotions"] is List) return json["promotions"] as List;
    if (json["eligiblePromotions"] is List) {
      return json["eligiblePromotions"] as List;
    }
    return const [];
  }

  static List<EligiblePromotion> _parsePromotions(List<dynamic> raw) {
    final result = <EligiblePromotion>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        result.add(EligiblePromotion.fromJson(item));
      }
    }
    return result;
  }
}

class EligiblePromotion {
  EligiblePromotion({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.discountType,
    required this.discountValue,
  });

  final dynamic id;
  final String? code;
  final String? name;
  final String? description;
  final String? discountType;
  final num? discountValue;

  factory EligiblePromotion.fromJson(Map<String, dynamic> json) {
    return EligiblePromotion(
      id: json["id"] ?? json["promotionId"],
      code: (json["code"] ?? json["promoCode"])?.toString(),
      name: (json["name"] ?? json["title"])?.toString(),
      description: json["description"]?.toString(),
      discountType: json["discountType"]?.toString(),
      discountValue: _toNum(json["discountValue"]),
    );
  }

  /// Best available label for the dropdown — the promo code itself,
  /// falling back to the promotion's name if no code is present.
  String get displayLabel {
    final trimmedCode = code?.trim();
    if (trimmedCode != null && trimmedCode.isNotEmpty) return trimmedCode;
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) return trimmedName;
    return 'Promo';
  }

  /// Value used to key this promotion in the dropdown / checkout payload.
  String get value => (code?.trim().isNotEmpty ?? false) ? code!.trim() : id.toString();
}

num? _toNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}
