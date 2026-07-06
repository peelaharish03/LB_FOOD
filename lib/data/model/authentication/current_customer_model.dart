class CurrentCustomerModel {
  CurrentCustomerModel({
    this.id,
    this.username,
    this.email,
    this.mobile,
    this.firstName,
    this.lastName,
    this.roles,
    this.b2bUnitId,
    this.b2bUnit,
    this.storeId,
    this.store,
  });

  String? id;
  String? username;
  String? email;
  String? mobile;
  String? firstName;
  String? lastName;
  List<String>? roles;
  String? b2bUnitId;
  B2BUnit? b2bUnit;
  dynamic storeId;
  dynamic store;

  factory CurrentCustomerModel.fromJson(Map<String, dynamic> json) {
    return CurrentCustomerModel(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      mobile: json['mobile'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      roles: json['roles'] != null
          ? List<String>.from(json['roles'])
          : [],
      b2bUnitId: json['b2bUnitId'],
      b2bUnit: json['b2bUnit'] != null
          ? B2BUnit.fromJson(json['b2bUnit'])
          : null,
      storeId: json['storeId'],
      store: json['store'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'mobile': mobile,
      'firstName': firstName,
      'lastName': lastName,
      'roles': roles,
      'b2bUnitId': b2bUnitId,
      'b2bUnit': b2bUnit?.toJson(),
      'storeId': storeId,
      'store': store,
    };
  }
}

class B2BUnit {
  B2BUnit({
    this.id,
    this.name,
    this.companyCode,
    this.tanNumber,
    this.cinNumber,
    this.gstNumber,
    this.panNumber,
    this.salaryDate,
    this.isStartup,
    this.isBootstrapped,
    this.type,
    this.status,
    this.businessRole,
    this.contactEmail,
    this.contactPhone,
    this.website,
    this.logo,
    this.additionalAttributes,
    this.address,
    this.addresses,
    this.groupId,
    this.groupName,
  });

  String? id;
  String? name;
  dynamic companyCode;
  dynamic tanNumber;
  dynamic cinNumber;
  dynamic gstNumber;
  dynamic panNumber;
  dynamic salaryDate;
  dynamic isStartup;
  dynamic isBootstrapped;
  String? type;
  String? status;
  String? businessRole;
  String? contactEmail;
  String? contactPhone;
  String? website;
  dynamic logo;
  Map<String, dynamic>? additionalAttributes;
  dynamic address;
  dynamic addresses;
  dynamic groupId;
  dynamic groupName;

  factory B2BUnit.fromJson(Map<String, dynamic> json) {
    return B2BUnit(
      id: json['id'],
      name: json['name'],
      companyCode: json['companyCode'],
      tanNumber: json['tanNumber'],
      cinNumber: json['cinNumber'],
      gstNumber: json['gstNumber'],
      panNumber: json['panNumber'],
      salaryDate: json['salaryDate'],
      isStartup: json['isStartup'],
      isBootstrapped: json['isBootstrapped'],
      type: json['type'],
      status: json['status'],
      businessRole: json['businessRole'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      website: json['website'],
      logo: json['logo'],
      additionalAttributes: json['additionalAttributes'] != null
          ? Map<String, dynamic>.from(json['additionalAttributes'])
          : {},
      address: json['address'],
      addresses: json['addresses'],
      groupId: json['groupId'],
      groupName: json['groupName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'companyCode': companyCode,
      'tanNumber': tanNumber,
      'cinNumber': cinNumber,
      'gstNumber': gstNumber,
      'panNumber': panNumber,
      'salaryDate': salaryDate,
      'isStartup': isStartup,
      'isBootstrapped': isBootstrapped,
      'type': type,
      'status': status,
      'businessRole': businessRole,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'website': website,
      'logo': logo,
      'additionalAttributes': additionalAttributes,
      'address': address,
      'addresses': addresses,
      'groupId': groupId,
      'groupName': groupName,
    };
  }
}