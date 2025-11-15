class ReOrderModel {
  ReOrderModel({
    required this.message,
    required this.status,
    required this.data,
  });

  final String? message;
  final String? status;
  final Data? data;

  factory ReOrderModel.fromJson(Map<String, dynamic> json) {
    return ReOrderModel(
      message: json["message"],
      status: json["status"],
      data: json["data"] == null ? null : Data.fromJson(json["data"]),
    );
  }
}

class Data {
  Data({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.username,
    required this.mobileNumber,
    required this.userAddress,
    required this.businessId,
    required this.businessName,
    required this.businessContactNumber,
    required this.shippingAddressId,
    required this.notes,
    required this.timmimgs,
    required this.businessAddress,
    required this.totalAmount,
    required this.totalTaxAmount,
    required this.taxInclusive,
    required this.paymentStatus,
    required this.paymentTransactionId,
    required this.orderStatus,
    required this.deliveryStatus,
    required this.createdDate,
    required this.updatedDate,
    required this.deliveryPartnerId,
    required this.deliveryPartnerName,
    required this.deliveryPartnerMobileNumber,
    required this.selfOrder,
    required this.orderItems,
  });

  final num? id;
  final String? orderNumber;
  final num? userId;
  final String? username;
  final String? mobileNumber;
  final UserAddress? userAddress;
  final num? businessId;
  final String? businessName;
  final dynamic businessContactNumber;
  final num? shippingAddressId;
  final dynamic notes;
  final dynamic timmimgs;
  final BusinessAddress? businessAddress;
  final num? totalAmount;
  final dynamic totalTaxAmount;
  final dynamic taxInclusive;
  final String? paymentStatus;
  final String? paymentTransactionId;
  final String? orderStatus;
  final dynamic deliveryStatus;
  final DateTime? createdDate;
  final DateTime? updatedDate;
  final dynamic deliveryPartnerId;
  final dynamic deliveryPartnerName;
  final dynamic deliveryPartnerMobileNumber;
  final bool? selfOrder;
  final List<dynamic> orderItems;

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      id: json["id"],
      orderNumber: json["orderNumber"],
      userId: json["userId"],
      username: json["username"],
      mobileNumber: json["mobileNumber"],
      userAddress: json["userAddress"] == null
          ? null
          : UserAddress.fromJson(json["userAddress"]),
      businessId: json["businessId"],
      businessName: json["businessName"],
      businessContactNumber: json["businessContactNumber"],
      shippingAddressId: json["shippingAddressId"],
      notes: json["notes"],
      timmimgs: json["timmimgs"],
      businessAddress: json["businessAddress"] == null
          ? null
          : BusinessAddress.fromJson(json["businessAddress"]),
      totalAmount: json["totalAmount"],
      totalTaxAmount: json["totalTaxAmount"],
      taxInclusive: json["taxInclusive"],
      paymentStatus: json["paymentStatus"],
      paymentTransactionId: json["paymentTransactionId"],
      orderStatus: json["orderStatus"],
      deliveryStatus: json["deliveryStatus"],
      createdDate: DateTime.tryParse(json["createdDate"] ?? ""),
      updatedDate: DateTime.tryParse(json["updatedDate"] ?? ""),
      deliveryPartnerId: json["deliveryPartnerId"],
      deliveryPartnerName: json["deliveryPartnerName"],
      deliveryPartnerMobileNumber: json["deliveryPartnerMobileNumber"],
      selfOrder: json["selfOrder"],
      orderItems: json["orderItems"] == null
          ? []
          : List<dynamic>.from(json["orderItems"]!.map((x) => x)),
    );
  }
}

class BusinessAddress {
  BusinessAddress({
    required this.id,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.postalCode,
  });

  final num? id;
  final String? addressLine1;
  final String? city;
  final String? state;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? postalCode;

  factory BusinessAddress.fromJson(Map<String, dynamic> json) {
    return BusinessAddress(
      id: json["id"],
      addressLine1: json["addressLine1"],
      city: json["city"],
      state: json["state"],
      country: json["country"],
      latitude: json["latitude"],
      longitude: json["longitude"],
      postalCode: json["postalCode"],
    );
  }
}

class UserAddress {
  UserAddress({
    required this.id,
    required this.addressLine1,
    required this.addressLine2,
    required this.street,
    required this.city,
    required this.state,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.postalCode,
    required this.userId,
    required this.isDefault,
  });

  final num? id;
  final String? addressLine1;
  final String? addressLine2;
  final String? street;
  final String? city;
  final String? state;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? postalCode;
  final num? userId;
  final bool? isDefault;

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json["id"],
      addressLine1: json["addressLine1"],
      addressLine2: json["addressLine2"],
      street: json["street"],
      city: json["city"],
      state: json["state"],
      country: json["country"],
      latitude: json["latitude"],
      longitude: json["longitude"],
      postalCode: json["postalCode"],
      userId: json["userId"],
      isDefault: json["isDefault"],
    );
  }
}
