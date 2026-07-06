class Attribute {
  final int? id;
  final String? attributeName;
  final String? attributeValue;

  Attribute({
    required this.id,
    required this.attributeName,
    required this.attributeValue,
  });

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
      id: json["id"],
      attributeName: json["attributeName"],
      attributeValue: json["attributeValue"],
    );
  }
}

class Media {
  final String? mediaType;
  final String? url;

  Media({required this.mediaType, required this.url});

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(mediaType: json["mediaType"], url: json["url"]);
  }
}

class Content {
  final dynamic id;
  final String? name;
  final String? shortCode;
  final bool? ignoreTax;
  final bool? discount;
  final String? description;
  final dynamic price;
  final bool? available;
  final String? shopifyProductId;
  final String? shopifyVariantId;
  final dynamic businessId;
  final dynamic categoryId;
  final String? categoryName;
  final String? businessName;
  final List<Media>? media;
  final List<Attribute> attributes;
  final String? status;

  Content({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.ignoreTax,
    required this.discount,
    required this.description,
    required this.price,
    required this.available,
    this.shopifyProductId,
    this.shopifyVariantId,
    required this.businessId,
    required this.categoryId,
    this.categoryName,
    this.businessName,
    this.media,
    required this.attributes,
    this.status,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    final categories = json["categories"];

    return Content(
      id: json["id"],
      name: json["name"],
      shortCode: json["shortCode"] ?? json["code"],
      ignoreTax: json["ignoreTax"] ?? false,
      discount: json["discount"] ?? true,
      description: json["description"] ?? json["shortDescription"],
      price: _parsePrice(json["price"]),
      available: json["available"] ?? json["active"] ?? true,
      shopifyProductId: json["shopifyProductId"],
      shopifyVariantId: json["shopifyVariantId"],
      businessId: json["businessId"] ?? json["storeId"],
      businessName: json["businessName"],
      categoryId: json["categoryId"] ?? _firstCategoryValue(categories, "id"),
      categoryName:
          json["categoryName"] ??
          _firstCategoryValue(categories, "name") ??
          _firstCategoryValue(categories, "code"),
      media: _parseMedia(json),
      attributes: _parseAttributes(json),
      status: json["status"] ?? json["approvalStatus"],
    );
  }

  static dynamic _firstCategoryValue(dynamic categories, String key) {
    if (categories is List && categories.isNotEmpty) {
      final first = categories.first;
      if (first is Map<String, dynamic>) return first[key];
      if (first is Map) return first[key];
    }
    return null;
  }

  static List<Media> _parseMedia(Map<String, dynamic> json) {
    final media = json["media"];
    if (media is List) {
      return media
          .whereType<Map>()
          .map((item) => Media.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    final urls = <String>[];
    final imageUrls = json["imageUrls"];
    if (imageUrls is List) {
      for (final image in imageUrls) {
        if (image is String) {
          urls.add(image);
        } else if (image is Map && image["url"] != null) {
          urls.add(image["url"].toString());
        }
      }
    }
    if (json["thumbnail"] != null) urls.add(json["thumbnail"].toString());

    return urls
        .where((url) => url.isNotEmpty)
        .map((url) => Media(mediaType: "IMAGE", url: url))
        .toList();
  }

  static List<Attribute> _parseAttributes(Map<String, dynamic> json) {
    final attributes = json["attributes"] ?? json["attributeValues"];
    if (attributes is! List) return [];

    return attributes.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      final attribute = map["attribute"];
      final attributeMap = attribute is Map ? attribute : null;

      return Attribute(
        id: map["id"] ?? attributeMap?["id"],
        attributeName:
            map["attributeName"] ??
            map["name"] ??
            attributeMap?["attributeName"] ??
            attributeMap?["name"],
        attributeValue:
            map["attributeValue"] ??
            map["value"] ??
            map["values"]?.toString() ??
            attributeMap?["attributeValue"],
      );
    }).toList();
  }

  static double? _parsePrice(dynamic price) {
    if (price == null) return null;
    if (price is num) return price.toDouble();
    if (price is String) return double.tryParse(price);
    if (price is Map) {
      final value = price["price"];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
    }
    return null;
  }
}

class Pageable {
  final List<dynamic> sort;
  final int? pageNumber;
  final int? pageSize;
  final int? offset;
  final bool? paged;
  final bool? unpaged;

  Pageable({
    required this.sort,
    required this.pageNumber,
    required this.pageSize,
    required this.offset,
    required this.paged,
    required this.unpaged,
  });

  factory Pageable.fromJson(Map<String, dynamic> json) {
    return Pageable(
      sort:
          json["sort"] == null
              ? []
              : List<dynamic>.from(json["sort"].map((x) => x)),
      pageNumber: json["pageNumber"],
      pageSize: json["pageSize"],
      offset: json["offset"],
      paged: json["paged"],
      unpaged: json["unpaged"],
    );
  }
}
