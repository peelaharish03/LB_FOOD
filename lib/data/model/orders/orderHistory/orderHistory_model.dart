class OrderHistoryModel {
  OrderHistoryModel({
    required this.message,
    required this.status,
    required this.data,
  });

  final String? message;
  final String? status;
  final Data? data;

  factory OrderHistoryModel.fromJson(Map<String, dynamic> json) {
    final wrappedData = json["data"];
    final pageJson =
        wrappedData is Map
            ? _asStringKeyMap(wrappedData)
            : _looksLikePagedResponse(json)
                ? _asStringKeyMap(json)
                : <String, dynamic>{};

    return OrderHistoryModel(
      message: _asString(json["message"]),
      status: _asString(json["status"]),
      data: Data.fromJson(pageJson),
    );
  }

  Map<String, dynamic> toJson() => {
    "message": message,
    "status": status,
    "data": data?.toJson(),
  };
}

class Data {
  Data({
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
  });

  final List<Content> content;
  final Pageable? pageable;
  final int? totalElements;
  final int? totalPages;
  final bool? last;
  final int? size;
  final int? number;
  final List<Sort> sort;
  final int? numberOfElements;
  final bool? first;
  final bool? empty;

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      content: _modelList(json["content"], Content.fromJson),
      pageable:
          json["pageable"] is Map
              ? Pageable.fromJson(_asStringKeyMap(json["pageable"]))
              : null,
      totalElements: _asInt(json["totalElements"]),
      totalPages: _asInt(json["totalPages"]),
      last: _asBool(json["last"]),
      size: _asInt(json["size"]),
      number: _asInt(json["number"]),
      sort: _modelList(json["sort"], Sort.fromJson),
      numberOfElements: _asInt(json["numberOfElements"]),
      first: _asBool(json["first"]),
      empty: _asBool(json["empty"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "content": content.map((x) => x.toJson()).toList(),
    "pageable": pageable?.toJson(),
    "totalElements": totalElements,
    "totalPages": totalPages,
    "last": last,
    "size": size,
    "number": number,
    "sort": sort.map((x) => x.toJson()).toList(),
    "numberOfElements": numberOfElements,
    "first": first,
    "empty": empty,
  };
}

class Content {
  Content({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.username,
    required this.mobileNumber,
    required this.address,
    required this.businessId,
    required this.businessName,
    required this.storeId,
    required this.b2bUnitId,
    required this.shippingAddressId,
    required this.totalAmount,
    required this.totalTaxAmount,
    required this.taxInclusive,
    required this.paymentStatus,
    required this.paymentTransactionId,
    required this.orderStatus,
    required this.createdDate,
    required this.updatedDate,
    required this.orderItems,
  });

  final String? id;
  final String? orderNumber;
  final String? userId;
  final String? username;
  final String? mobileNumber;
  final Address? address;
  final String? businessId;
  final String? businessName;
  final String? storeId;
  final String? b2bUnitId;
  final String? shippingAddressId;
  final num? totalAmount;
  final num? totalTaxAmount;
  final bool? taxInclusive;
  final String? paymentStatus;
  final String? paymentTransactionId;
  final String? orderStatus;
  final DateTime? createdDate;
  final DateTime? updatedDate;
  final List<OrderItem> orderItems;

  factory Content.fromJson(Map<String, dynamic> json) {
    final orderItemsJson = json["orderItems"] ?? json["lineItems"];
    final b2bUnitId = _asString(json["b2bUnitId"]);
    final storeId = _asString(json["storeId"]);

    return Content(
      id: _asString(json["id"]),
      orderNumber:
          _asString(json["orderNumber"] ?? json["orderNo"]) ??
          _asString(json["id"]),
      userId: _asString(json["userId"]),
      username: _asString(json["username"]),
      mobileNumber: _asString(json["mobileNumber"] ?? json["mobile"]),
      address:
          json["address"] is Map
              ? Address.fromJson(_asStringKeyMap(json["address"]))
              : null,
      businessId: _asString(json["businessId"]) ?? b2bUnitId ?? storeId,
      businessName: _asString(
        json["businessName"] ?? json["storeName"] ?? json["b2bUnitName"],
      ),
      storeId: storeId,
      b2bUnitId: b2bUnitId,
      shippingAddressId: _asString(json["shippingAddressId"]),
      totalAmount: _asNum(
        json["totalAmount"] ?? json["totalPrice"] ?? json["grandTotal"],
      ),
      totalTaxAmount: _asNum(json["totalTaxAmount"] ?? json["totalTax"]),
      taxInclusive: _asBool(json["taxInclusive"]),
      paymentStatus: _asString(json["paymentStatus"]),
      paymentTransactionId: _asString(
        json["paymentTransactionId"] ?? json["transactionId"],
      ),
      orderStatus: _asString(json["orderStatus"] ?? json["status"]),
      createdDate: _asDateTime(json["createdDate"]),
      updatedDate: _asDateTime(json["updatedDate"]),
      orderItems: _modelList(orderItemsJson, OrderItem.fromJson),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "orderNumber": orderNumber,
    "userId": userId,
    "username": username,
    "mobileNumber": mobileNumber,
    "address": address?.toJson(),
    "businessId": businessId,
    "businessName": businessName,
    "storeId": storeId,
    "b2bUnitId": b2bUnitId,
    "shippingAddressId": shippingAddressId,
    "totalAmount": totalAmount,
    "totalTaxAmount": totalTaxAmount,
    "taxInclusive": taxInclusive,
    "paymentStatus": paymentStatus,
    "paymentTransactionId": paymentTransactionId,
    "orderStatus": orderStatus,
    "createdDate": createdDate?.toIso8601String(),
    "updatedDate": updatedDate?.toIso8601String(),
    "orderItems": orderItems.map((x) => x.toJson()).toList(),
  };
}

class Address {
  Address({
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

  final String? id;
  final String? addressLine1;
  final String? addressLine2;
  final String? street;
  final String? city;
  final String? state;
  final String? country;
  final num? latitude;
  final num? longitude;
  final String? postalCode;
  final String? userId;
  final bool? isDefault;

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: _asString(json["id"]),
      addressLine1: _asString(json["addressLine1"]),
      addressLine2: _asString(json["addressLine2"]),
      street: _asString(json["street"]),
      city: _asString(json["city"]),
      state: _asString(json["state"]),
      country: _asString(json["country"]),
      latitude: _asNum(json["latitude"]),
      longitude: _asNum(json["longitude"]),
      postalCode: _asString(json["postalCode"]),
      userId: _asString(json["userId"]),
      isDefault: _asBool(json["isDefault"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "addressLine1": addressLine1,
    "addressLine2": addressLine2,
    "street": street,
    "city": city,
    "state": state,
    "country": country,
    "latitude": latitude,
    "longitude": longitude,
    "postalCode": postalCode,
    "userId": userId,
    "isDefault": isDefault,
  };
}

class OrderItem {
  OrderItem({
    required this.id,
    required this.productId,
    required this.productCode,
    required this.quantity,
    required this.price,
    required this.entryNumber,
    required this.productName,
    required this.media,
    required this.taxAmount,
    required this.taxPercentage,
    required this.totalAmount,
    required this.taxIgnored,
    required this.status,
    required this.fulfillmentStatus,
  });

  final String? id;
  final String? productId;
  final String? productCode;
  final int? quantity;
  final num? price;
  final int? entryNumber;
  final String? productName;
  final List<Media> media;
  final num? taxAmount;
  final int? taxPercentage;
  final num? totalAmount;
  final bool? taxIgnored;
  final String? status;
  final String? fulfillmentStatus;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: _asString(json["id"]),
      productId: _asString(json["productId"]),
      productCode: _asString(json["productCode"]),
      quantity: _asInt(json["quantity"]),
      price: _asNum(json["price"] ?? json["unitPrice"]),
      entryNumber: _asInt(json["entryNumber"]),
      productName: _asString(json["productName"] ?? json["name"]),
      media: _modelList(json["media"] ?? json["mediaList"], Media.fromJson),
      taxAmount: _asNum(json["taxAmount"]),
      taxPercentage: _asInt(json["taxPercentage"]),
      totalAmount: _asNum(json["totalAmount"] ?? json["totalPrice"]),
      taxIgnored: _asBool(json["taxIgnored"]),
      status: _asString(json["status"]),
      fulfillmentStatus: _asString(json["fulfillmentStatus"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "productId": productId,
    "productCode": productCode,
    "quantity": quantity,
    "price": price,
    "entryNumber": entryNumber,
    "productName": productName,
    "media": media.map((x) => x.toJson()).toList(),
    "taxAmount": taxAmount,
    "taxPercentage": taxPercentage,
    "totalAmount": totalAmount,
    "taxIgnored": taxIgnored,
    "status": status,
    "fulfillmentStatus": fulfillmentStatus,
  };
}

class Media {
  Media({required this.mediaType, required this.url});

  final String? mediaType;
  final String? url;

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      mediaType: _asString(json["mediaType"]),
      url: _asString(json["url"]),
    );
  }

  Map<String, dynamic> toJson() => {"mediaType": mediaType, "url": url};
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
  final int? pageNumber;
  final int? pageSize;
  final num? offset;
  final bool? paged;
  final bool? unpaged;

  factory Pageable.fromJson(Map<String, dynamic> json) {
    return Pageable(
      sort: _modelList(json["sort"], Sort.fromJson),
      pageNumber: _asInt(json["pageNumber"]),
      pageSize: _asInt(json["pageSize"]),
      offset: _asNum(json["offset"]),
      paged: _asBool(json["paged"]),
      unpaged: _asBool(json["unpaged"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "sort": sort.map((x) => x.toJson()).toList(),
    "pageNumber": pageNumber,
    "pageSize": pageSize,
    "offset": offset,
    "paged": paged,
    "unpaged": unpaged,
  };
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
      direction: _asString(json["direction"]),
      property: _asString(json["property"]),
      ignoreCase: _asBool(json["ignoreCase"]),
      nullHandling: _asString(json["nullHandling"]),
      ascending: _asBool(json["ascending"]),
      descending: _asBool(json["descending"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "direction": direction,
    "property": property,
    "ignoreCase": ignoreCase,
    "nullHandling": nullHandling,
    "ascending": ascending,
    "descending": descending,
  };
}

Map<String, dynamic> _asStringKeyMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return {};
}

bool _looksLikePagedResponse(Map<String, dynamic> json) {
  return json.containsKey("content") ||
      json.containsKey("pageable") ||
      json.containsKey("totalElements") ||
      json.containsKey("totalPages") ||
      json.containsKey("last") ||
      json.containsKey("number") ||
      json.containsKey("size");
}

List<T> _modelList<T>(
  dynamic value,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (value is! Iterable) return [];
  return value
      .whereType<Map>()
      .map((item) => fromJson(_asStringKeyMap(item)))
      .toList();
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

num? _asNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '');
}

bool? _asBool(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase();
  if (text == 'true') return true;
  if (text == 'false') return false;
  return null;
}

DateTime? _asDateTime(dynamic value) {
  final text = _asString(value);
  return text == null ? null : DateTime.tryParse(text);
}
