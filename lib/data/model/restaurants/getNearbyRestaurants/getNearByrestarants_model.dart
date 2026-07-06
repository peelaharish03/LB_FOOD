class GetNearByStoresModel {
  GetNearByStoresModel({
    required this.content,
    required this.pageable,
    required this.last,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.size,
    required this.number,
    required this.sort,
    required this.numberOfElements,
    required this.empty,
  });

  final List<StoreContent> content;
  final Pageable? pageable;
  final bool? last;
  final int? totalElements;
  final int? totalPages;
  final bool? first;
  final int? size;
  final int? number;
  final List<dynamic> sort;
  final int? numberOfElements;
  final bool? empty;

  factory GetNearByStoresModel.fromJson(Map<String, dynamic> json) {
    return GetNearByStoresModel(
      content: json["content"] == null
          ? []
          : List<StoreContent>.from(
              json["content"].map((x) => StoreContent.fromJson(x))),
      pageable: json["pageable"] == null
          ? null
          : Pageable.fromJson(json["pageable"]),
      last: json["last"],
      totalElements: json["totalElements"],
      totalPages: json["totalPages"],
      first: json["first"],
      size: json["size"],
      number: json["number"],
      sort: json["sort"] == null
          ? []
          : List<dynamic>.from(json["sort"]),
      numberOfElements: json["numberOfElements"],
      empty: json["empty"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "content": content.map((store) => store.toJson()).toList(),
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

class StoreContent {
  StoreContent({
    required this.id,
    required this.code,
    required this.name,
    required this.b2bUnitId,
    required this.storeType,
    required this.active,
    required this.enableStockCheck,
    required this.defaultLanguage,
    required this.languages,
    required this.defaultCurrencyIsoCode,
    required this.defaultWarehouseId,
    required this.defaultWarehouseName,
    required this.defaultCatalogId,
    required this.warehouseIds,
    required this.catalogIds,
    required this.approvalStatus,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  final String? id;
  final String? code;
  final String? name;
  final String? b2bUnitId;
  final dynamic storeType;
  final bool? active;
  final bool? enableStockCheck;
  final dynamic defaultLanguage;
  final dynamic languages;
  final String? defaultCurrencyIsoCode;
  final dynamic defaultWarehouseId;
  final dynamic defaultWarehouseName;
  final String? defaultCatalogId;
  final List<String> warehouseIds;
  final List<String> catalogIds;
  final String? approvalStatus;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;

  factory StoreContent.fromJson(Map<String, dynamic> json) {
    return StoreContent(
      id: json["id"],
      code: json["code"],
      name: json["name"],
      b2bUnitId: json["b2bUnitId"],
      storeType: json["storeType"],
      active: json["active"],
      enableStockCheck: json["enableStockCheck"],
      defaultLanguage: json["defaultLanguage"],
      languages: json["languages"],
      defaultCurrencyIsoCode: json["defaultCurrencyIsoCode"],
      defaultWarehouseId: json["defaultWarehouseId"],
      defaultWarehouseName: json["defaultWarehouseName"],
      defaultCatalogId: json["defaultCatalogId"],
      warehouseIds: json["warehouseIds"] == null
          ? []
          : List<String>.from(json["warehouseIds"]),
      catalogIds: json["catalogIds"] == null
          ? []
          : List<String>.from(json["catalogIds"]),
      approvalStatus: json["approvalStatus"],
      latitude: json["latitude"]?.toDouble(),
      longitude: json["longitude"]?.toDouble(),
      distanceKm: json["distanceKm"]?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "code": code,
      "name": name,
      "b2bUnitId": b2bUnitId,
      "storeType": storeType,
      "active": active,
      "enableStockCheck": enableStockCheck,
      "defaultLanguage": defaultLanguage,
      "languages": languages,
      "defaultCurrencyIsoCode": defaultCurrencyIsoCode,
      "defaultWarehouseId": defaultWarehouseId,
      "defaultWarehouseName": defaultWarehouseName,
      "defaultCatalogId": defaultCatalogId,
      "warehouseIds": warehouseIds,
      "catalogIds": catalogIds,
      "approvalStatus": approvalStatus,
      "latitude": latitude,
      "longitude": longitude,
      "distanceKm": distanceKm,
    };
  }
}

class Pageable {
  Pageable({
    required this.pageNumber,
    required this.pageSize,
    required this.sort,
    required this.offset,
    required this.paged,
    required this.unpaged,
  });

  final int? pageNumber;
  final int? pageSize;
  final List<dynamic> sort;
  final int? offset;
  final bool? paged;
  final bool? unpaged;

  factory Pageable.fromJson(Map<String, dynamic> json) {
    return Pageable(
      pageNumber: json["pageNumber"],
      pageSize: json["pageSize"],
      sort: json["sort"] == null
          ? []
          : List<dynamic>.from(json["sort"]),
      offset: json["offset"],
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
