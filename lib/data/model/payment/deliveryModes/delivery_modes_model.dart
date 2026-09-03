/// Response model for `GET /api/delivery-modes`.
///
/// Same Spring-page shape as payment-methods:
/// ```json
/// { "content": [ { "id": ..., "code": "STANDARD", "name": "STANDARD",
///   "description": "...", "active": true } ], ... }
/// ```
class DeliveryModesModel {
  DeliveryModesModel({required this.modes});

  final List<DeliveryMode> modes;

  /// Only the modes the backend currently has switched on.
  List<DeliveryMode> get activeModes =>
      modes.where((m) => m.active && m.hasUsableCode).toList();

  factory DeliveryModesModel.fromJson(dynamic json) {
    return DeliveryModesModel(modes: _parseModes(_extractList(json)));
  }

  static List<dynamic> _extractList(dynamic json) {
    if (json is List) return json;
    if (json is Map<String, dynamic>) {
      if (json["content"] is List) return json["content"] as List;
      final data = json["data"];
      if (data is List) return data;
      if (data is Map<String, dynamic> && data["content"] is List) {
        return data["content"] as List;
      }
      if (json["deliveryModes"] is List) return json["deliveryModes"] as List;
    }
    return const [];
  }

  static List<DeliveryMode> _parseModes(List<dynamic> raw) {
    final result = <DeliveryMode>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        result.add(DeliveryMode.fromJson(item));
      }
    }
    return result;
  }
}

class DeliveryMode {
  DeliveryMode({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.active,
  });

  final dynamic id;
  final String? code;
  final String? name;
  final String? description;
  final bool active;

  factory DeliveryMode.fromJson(Map<String, dynamic> json) {
    return DeliveryMode(
      id: json["id"],
      code: json["code"]?.toString(),
      name: json["name"]?.toString(),
      description: json["description"]?.toString(),
      active: json["active"] == null ? true : json["active"] == true,
    );
  }

  bool get hasUsableCode => (code?.trim().isNotEmpty ?? false);

  /// Label shown in the delivery-mode picker.
  String get displayName {
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) return trimmedName;
    final trimmedCode = code?.trim();
    if (trimmedCode != null && trimmedCode.isNotEmpty) return trimmedCode;
    return 'Delivery mode';
  }

  /// Value sent to checkout as `shippingMethod`.
  String get checkoutCode => code!.trim();
}
