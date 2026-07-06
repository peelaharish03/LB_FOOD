import 'package:local_basket/data/model/restaurants/menu_content_model.dart'
    show Content;

class GetMenuByRestaurantIdModel {
  GetMenuByRestaurantIdModel({
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

  factory GetMenuByRestaurantIdModel.fromJson(Map<String, dynamic> json) {
    return GetMenuByRestaurantIdModel(
      content: json["content"] == null
          ? []
          : List<Content>.from(
              json["content"].map((x) => Content.fromJson(x)),
            ),
      pageable: json["pageable"] == null
          ? null
          : Pageable.fromJson(json["pageable"]),
      totalPages: json["totalPages"],
      totalElements: json["totalElements"],
      last: json["last"],
      size: json["size"],
      number: json["number"],
      sort: json["sort"] == null ? [] : List<dynamic>.from(json["sort"]),
      numberOfElements: json["numberOfElements"],
      first: json["first"],
      empty: json["empty"],
    );
  }
}

class Pageable {
  Pageable({
    this.pageNumber,
    this.pageSize,
    this.sort,
    this.offset,
    this.paged,
    this.unpaged,
  });

  final int? pageNumber;
  final int? pageSize;
  final List<dynamic>? sort;
  final int? offset;
  final bool? paged;
  final bool? unpaged;

  factory Pageable.fromJson(Map<String, dynamic> json) {
    return Pageable(
      pageNumber: json["pageNumber"],
      pageSize: json["pageSize"],
      sort: json["sort"] == null ? [] : List<dynamic>.from(json["sort"]),
      offset: json["offset"],
      paged: json["paged"],
      unpaged: json["unpaged"],
    );
  }
}
