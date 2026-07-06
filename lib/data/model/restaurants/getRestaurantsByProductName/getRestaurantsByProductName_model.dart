import 'package:local_basket/data/model/restaurants/getNearbyRestaurants/getNearByrestarants_model.dart'
    show StoreContent;

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

  final List<StoreContent> content;
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
      content:
          json["content"] == null
              ? []
              : List<StoreContent>.from(
                json["content"]!.map((x) => StoreContent.fromJson(x)),
              ),
      pageable:
          json["pageable"] == null ? null : Pageable.fromJson(json["pageable"]),
      totalPages: json["totalPages"],
      totalElements: json["totalElements"],
      last: json["last"],
      size: json["size"],
      number: json["number"],
      sort:
          json["sort"] == null
              ? []
              : List<dynamic>.from(json["sort"]!.map((x) => x)),
      numberOfElements: json["numberOfElements"],
      first: json["first"],
      empty: json["empty"],
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
      sort:
          json["sort"] == null
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
