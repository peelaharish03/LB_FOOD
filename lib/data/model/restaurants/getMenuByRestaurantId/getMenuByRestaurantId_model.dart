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
    final page = json["page"];
    final pageMap = page is Map ? Map<String, dynamic>.from(page) : null;

    final int? number = pageMap?["number"] ?? json["number"];
    final int? size = pageMap?["size"] ?? json["size"];
    final int? totalPages = pageMap?["totalPages"] ?? json["totalPages"];
    final int? totalElements =
        pageMap?["totalElements"] ?? json["totalElements"];

    return GetMenuByRestaurantIdModel(
      content: json["content"] == null
          ? []
          : List<Content>.from(
              json["content"].map((x) => Content.fromJson(x)),
            ),
      pageable: json["pageable"] == null
          ? null
          : Pageable.fromJson(json["pageable"]),
      totalPages: totalPages,
      totalElements: totalElements,
      last: json["last"] ??
          (totalPages != null && number != null
              ? number + 1 >= totalPages
              : null),
      size: size,
      number: number,
      sort: json["sort"] == null ? [] : List<dynamic>.from(json["sort"]),
      numberOfElements: pageMap?["totalElements"] ?? json["numberOfElements"],
      first: json["first"] ?? (number != null ? number == 0 : null),
      empty: json["empty"] ?? (json["content"] == null ? null : json["content"].isEmpty),
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
