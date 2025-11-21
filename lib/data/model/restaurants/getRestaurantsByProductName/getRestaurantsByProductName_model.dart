class GetRestaurantsByProductNameModel {
  GetRestaurantsByProductNameModel({
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
  final int? totalPages;
  final int? totalElements;
  final bool? last;
  final int? size;
  final int? number;
  final List<dynamic> sort;
  final int? numberOfElements;
  final bool? first;
  final bool? empty;

  factory GetRestaurantsByProductNameModel.fromJson(Map<String, dynamic> json) {
    return GetRestaurantsByProductNameModel(
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
          : List<dynamic>.from(json["sort"]!.map((x) => x)),
      numberOfElements: json["numberOfElements"],
      first: json["first"],
      empty: json["empty"],
    );
  }
}

class Content {
  Content({
    required this.id,
    required this.businessName,
    required this.approved,
    required this.categoryName,
    required this.creationDate,
    required this.userDto,
    required this.attributes,
    required this.mediaList,
  });

  final int? id;
  final String? businessName;
  final bool? approved;
  final String? categoryName;
  final DateTime? creationDate;
  final UserDto? userDto;
  final List<Attribute> attributes;
  final List<MediaList> mediaList;

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      id: json["id"],
      businessName: json["businessName"],
      approved: json["approved"],
      categoryName: json["categoryName"],
      creationDate: DateTime.tryParse(json["creationDate"] ?? ""),
      userDto:
          json["userDTO"] == null ? null : UserDto.fromJson(json["userDTO"]),
      attributes: json["attributes"] == null
          ? []
          : List<Attribute>.from(
              json["attributes"]!.map((x) => Attribute.fromJson(x))),
      mediaList: json["mediaList"] == null
          ? []
          : List<MediaList>.from(
              json["mediaList"]!.map((x) => MediaList.fromJson(x))),
    );
  }
}

class Attribute {
  Attribute({
    required this.id,
    required this.attributeName,
    required this.attributeValue,
  });

  final int? id;
  final String? attributeName;
  final String? attributeValue;

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
      id: json["id"],
      attributeName: json["attributeName"],
      attributeValue: json["attributeValue"],
    );
  }
}

class MediaList {
  MediaList({
    required this.mediaType,
    required this.url,
  });

  final String? mediaType;
  final String? url;

  factory MediaList.fromJson(Map<String, dynamic> json) {
    return MediaList(
      mediaType: json["mediaType"],
      url: json["url"],
    );
  }
}

class UserDto {
  UserDto({
    required this.id,
    required this.primaryContact,
    required this.lastLogOutDate,
    required this.recentActivityDate,
    required this.roles,
  });

  final int? id;
  final String? primaryContact;
  final DateTime? lastLogOutDate;
  final DateTime? recentActivityDate;
  final List<String> roles;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json["id"],
      primaryContact: json["primaryContact"],
      lastLogOutDate: DateTime.tryParse(json["lastLogOutDate"] ?? ""),
      recentActivityDate: DateTime.tryParse(json["recentActivityDate"] ?? ""),
      roles: json["roles"] == null
          ? []
          : List<String>.from(json["roles"]!.map((x) => x)),
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

  final List<dynamic> sort;
  final int? pageNumber;
  final int? pageSize;
  final int? offset;
  final bool? paged;
  final bool? unpaged;

  factory Pageable.fromJson(Map<String, dynamic> json) {
    return Pageable(
      sort: json["sort"] == null
          ? []
          : List<dynamic>.from(json["sort"]!.map((x) => x)),
      pageNumber: json["pageNumber"],
      pageSize: json["pageSize"],
      offset: json["offset"],
      paged: json["paged"],
      unpaged: json["unpaged"],
    );
  }
}
