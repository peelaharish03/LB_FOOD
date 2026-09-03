/// Response model for `GET /api/payment-methods`.
///
/// The API returns a Spring-style page:
/// ```json
/// { "content": [ { "id": ..., "code": "RAZORPAY", "name": "Online Payment",
///   "description": "...", "active": true }, ... ], ... }
/// ```
class PaymentMethodsModel {
  PaymentMethodsModel({required this.methods});

  final List<PaymentMethod> methods;

  /// Only the methods the backend currently has switched on.
  List<PaymentMethod> get activeMethods =>
      methods.where((m) => m.active && m.hasUsableCode).toList();

  factory PaymentMethodsModel.fromJson(dynamic json) {
    return PaymentMethodsModel(methods: _parseMethods(_extractList(json)));
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
      if (json["paymentMethods"] is List) return json["paymentMethods"] as List;
    }
    return const [];
  }

  static List<PaymentMethod> _parseMethods(List<dynamic> raw) {
    final result = <PaymentMethod>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        result.add(PaymentMethod.fromJson(item));
      }
    }
    return result;
  }
}

class PaymentMethod {
  PaymentMethod({
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

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json["id"],
      code: json["code"]?.toString(),
      name: json["name"]?.toString(),
      description: json["description"]?.toString(),
      active: json["active"] == null ? true : json["active"] == true,
    );
  }

  bool get hasUsableCode => (code?.trim().isNotEmpty ?? false);

  /// Cash on delivery is checked out through a different endpoint than the
  /// online (Razorpay) methods, so callers need to branch on this.
  bool get isCashOnDelivery => (code?.trim().toUpperCase() ?? '') == 'COD';

  /// Label shown in the payment-method picker.
  String get displayName {
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) return trimmedName;
    final trimmedCode = code?.trim();
    if (trimmedCode != null && trimmedCode.isNotEmpty) return trimmedCode;
    return 'Payment method';
  }

  /// Value sent to checkout as `paymentMethod`.
  String get checkoutCode => code!.trim();
}
