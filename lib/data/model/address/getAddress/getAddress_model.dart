class GetAddressModel {
  GetAddressModel({
    required this.content,
    required this.pageable,
    required this.totalElements,
    required this.totalPages,
    required this.last,
    required this.size,
    required this.number,
    required this.sort,
    required this.numberOfElements,
    required this.first,
    required this.empty,
    this.success,
    this.message,
  });

  final List<Content> content;
  final Pageable? pageable;
  final int? totalElements;
  final int? totalPages;
  final bool? last;
  final int? size;
  final int? number;
  final List<dynamic> sort;
  final int? numberOfElements;
  final bool? first;
  final bool? empty;
  final bool? success;
  final String? message;

  factory GetAddressModel.fromJson(Map<String, dynamic> json) {
    final source =
        json["data"] is Map<String, dynamic>
            ? Map<String, dynamic>.from(json["data"])
            : json;

    return GetAddressModel(
      content:
          source["content"] == null
              ? []
              : List<Content>.from(
                source["content"].map(
                  (x) => Content.fromJson(Map<String, dynamic>.from(x)),
                ),
              ),
      pageable:
          source["pageable"] == null
              ? null
              : Pageable.fromJson(
                Map<String, dynamic>.from(source["pageable"]),
              ),
      totalElements: _toInt(source["totalElements"]),
      totalPages: _toInt(source["totalPages"]),
      last: source["last"],
      size: _toInt(source["size"]),
      number: _toInt(source["number"]),
      sort:
          source["sort"] == null
              ? []
              : List<dynamic>.from(source["sort"].map((x) => x)),
      numberOfElements: _toInt(source["numberOfElements"]),
      first: source["first"],
      empty: source["empty"],
      success: json["success"],
      message: json["message"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "content": content.map((x) => x.toJson()).toList(),
      "pageable": pageable?.toJson(),
      "last": last,
      "totalElements": totalElements,
      "totalPages": totalPages,
      "first": first,
      "size": size,
      "number": number,
      "sort": sort,
      "numberOfElements": numberOfElements,
      "empty": empty,
    };
  }
}

class Content {
  Content({
    required this.userId,
    required this.userName,
    required this.address,
  });

  final String? userId;
  final String? userName;
  final Address? address;

  String? get id => address?.id;
  String? get addressLine1 => address?.line1;
  String? get addressLine2 => address?.line2;
  String? get street => address?.fullText;
  String? get city => address?.city;
  String? get state => address?.state;
  String? get country => address?.country;
  String? get postalCode => address?.postalCode;
  bool? get isDefault => false;

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      userId: json["userId"]?.toString(),
      userName: json["userName"]?.toString(),
      address:
          json["address"] == null
              ? null
              : Address.fromJson(Map<String, dynamic>.from(json["address"])),
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

class Address {
  Address({
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

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
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

class Pageable {
  Pageable({
    required this.sort,
    required this.pageNumber,
    required this.pageSize,
    required this.offset,
    required this.paged,
    required this.unpaged,
  });

  final List<dynamic> sort;
  final int? pageNumber;
  final int? pageSize;
  final int? offset;
  final bool? paged;
  final bool? unpaged;

  factory Pageable.fromJson(Map<String, dynamic> json) {
    return Pageable(
      sort:
          json["sort"] == null
              ? []
              : List<dynamic>.from(json["sort"].map((x) => x)),
      pageNumber: _toInt(json["pageNumber"]),
      pageSize: _toInt(json["pageSize"]),
      offset: _toInt(json["offset"]),
      paged: json["paged"],
      unpaged: json["unpaged"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "pageNumber": pageNumber,
      "pageSize": pageSize,
      "sort": sort,
      "offset": offset,
      "paged": paged,
      "unpaged": unpaged,
    };
  }
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
