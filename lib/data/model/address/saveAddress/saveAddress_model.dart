class SaveAddressModel {
  SaveAddressModel({
    required this.userId,
    required this.userName,
    required this.address,
  });

  final String? userId;
  final String? userName;
  final SavedAddress? address;

  factory SaveAddressModel.fromJson(Map<String, dynamic> json) {
    return SaveAddressModel(
      userId: json["userId"]?.toString(),
      userName: json["userName"]?.toString(),
      address:
          json["address"] == null
              ? null
              : SavedAddress.fromJson(
                Map<String, dynamic>.from(json["address"]),
              ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "userName": userName,
      "address": address?.toJson(),
    };
  }
}

class SavedAddress {
  SavedAddress({
    required this.id,
    required this.name,
    required this.addressType,
    required this.mobileNumber,
    required this.line1,
    required this.line2,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.fullText,
  });

  final String? id;
  final String? name;
  final String? addressType;
  final String? mobileNumber;
  final String? line1;
  final String? line2;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? fullText;

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json["id"]?.toString(),
      name: json["name"]?.toString(),
      addressType: json["addressType"]?.toString(),
      mobileNumber: json["mobileNumber"]?.toString(),
      line1: json["line1"]?.toString(),
      line2: json["line2"]?.toString(),
      city: json["city"]?.toString(),
      state: json["state"]?.toString(),
      country: json["country"]?.toString(),
      postalCode: json["postalCode"]?.toString(),
      fullText: json["fullText"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "addressType": addressType,
      "mobileNumber": mobileNumber,
      "line1": line1,
      "line2": line2,
      "city": city,
      "state": state,
      "country": country,
      "postalCode": postalCode,
      "fullText": fullText,
    };
  }
}
