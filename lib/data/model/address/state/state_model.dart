class StateModel {
  StateModel({
    required this.active,
    required this.code,
    required this.countryCode,
    required this.id,
    required this.name,
  });

  final bool? active;
  final String? code;
  final String? countryCode;
  final String id;
  final String name;

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      active: json["active"],
      code: json["code"]?.toString(),
      countryCode: json["countryCode"]?.toString(),
      id: json["id"]?.toString() ?? '',
      name: json["name"]?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "active": active,
      "code": code,
      "countryCode": countryCode,
      "id": id,
      "name": name,
    };
  }
}

class CityModel {
  CityModel({
    required this.active,
    required this.code,
    required this.countryCode,
    required this.id,
    required this.name,
    required this.stateCode,
  });

  final bool? active;
  final String? code;
  final String? countryCode;
  final String id;
  final String name;
  final String? stateCode;

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      active: json["active"],
      code: json["code"]?.toString(),
      countryCode: json["countryCode"]?.toString(),
      id: json["id"]?.toString() ?? '',
      name: json["name"]?.toString() ?? '',
      stateCode: json["stateCode"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "active": active,
      "code": code,
      "countryCode": countryCode,
      "id": id,
      "name": name,
      "stateCode": stateCode,
    };
  }
}
