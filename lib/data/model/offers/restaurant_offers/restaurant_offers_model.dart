class RestaurantOffersModel {
  RestaurantOffersModel({
    required this.message,
    required this.status,
    required this.data,
  });

  final String? message;
  final String? status;
  final Data? data;

  factory RestaurantOffersModel.fromJson(Map<String, dynamic> json) {
    return RestaurantOffersModel(
      message: json["message"],
      status: json["status"],
      data: json["data"] == null ? null : Data.fromJson(json["data"]),
    );
  }
}

class Data {
  Data({
    required this.content,
    required this.pageable,
    required this.totalPages,
    required this.totalElements,
    required this.last,
    required this.size,
    required this.number,
    required this.sort,
    required this.numberOfElements,
    required this.first,
    required this.empty,
  });

  final List<Content> content;
  final Pageable? pageable;
  final num? totalPages;
  final num? totalElements;
  final bool? last;
  final num? size;
  final num? number;
  final List<Sort> sort;
  final num? numberOfElements;
  final bool? first;
  final bool? empty;

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      content: json["content"] == null
          ? []
          : List<Content>.from(
              json["content"]!.map((x) => Content.fromJson(x))),
      pageable:
          json["pageable"] == null ? null : Pageable.fromJson(json["pageable"]),
      totalPages: json["totalPages"],
      totalElements: json["totalElements"],
      last: json["last"],
      size: json["size"],
      number: json["number"],
      sort: json["sort"] == null
          ? []
          : List<Sort>.from(json["sort"]!.map((x) => Sort.fromJson(x))),
      numberOfElements: json["numberOfElements"],
      first: json["first"],
      empty: json["empty"],
    );
  }
}

class Content {
  Content({
    required this.id,
    required this.name,
    required this.offerType,
    required this.value,
    required this.minOrderValue,
    required this.couponCode,
    required this.startDate,
    required this.endDate,
    required this.businessId,
    required this.active,
    required this.description,
    required this.productIds,
    required this.categoryIds,
    required this.targetType,
  });

  final num? id;
  final String? name;
  final String? offerType;
  final num? value;
  final num? minOrderValue;
  final String? couponCode;
  final DateTime? startDate;
  final DateTime? endDate;
  final num? businessId;
  final bool? active;
  final String? description;
  final List<dynamic> productIds;
  final List<dynamic> categoryIds;
  final String? targetType;

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      id: json["id"],
      name: json["name"],
      offerType: json["offerType"],
      value: json["value"],
      minOrderValue: json["minOrderValue"],
      couponCode: json["couponCode"],
      startDate: DateTime.tryParse(json["startDate"] ?? ""),
      endDate: DateTime.tryParse(json["endDate"] ?? ""),
      businessId: json["businessId"],
      active: json["active"],
      description: json["description"],
      productIds: json["productIds"] == null
          ? []
          : List<dynamic>.from(json["productIds"]!.map((x) => x)),
      categoryIds: json["categoryIds"] == null
          ? []
          : List<dynamic>.from(json["categoryIds"]!.map((x) => x)),
      targetType: json["targetType"],
    );
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

  final List<Sort> sort;
  final num? pageNumber;
  final num? pageSize;
  final num? offset;
  final bool? paged;
  final bool? unpaged;

  factory Pageable.fromJson(Map<String, dynamic> json) {
    return Pageable(
      sort: json["sort"] == null
          ? []
          : List<Sort>.from(json["sort"]!.map((x) => Sort.fromJson(x))),
      pageNumber: json["pageNumber"],
      pageSize: json["pageSize"],
      offset: json["offset"],
      paged: json["paged"],
      unpaged: json["unpaged"],
    );
  }
}

class Sort {
  Sort({
    required this.direction,
    required this.property,
    required this.ignoreCase,
    required this.nullHandling,
    required this.ascending,
    required this.descending,
  });

  final String? direction;
  final String? property;
  final bool? ignoreCase;
  final String? nullHandling;
  final bool? ascending;
  final bool? descending;

  factory Sort.fromJson(Map<String, dynamic> json) {
    return Sort(
      direction: json["direction"],
      property: json["property"],
      ignoreCase: json["ignoreCase"],
      nullHandling: json["nullHandling"],
      ascending: json["ascending"],
      descending: json["descending"],
    );
  }
}
