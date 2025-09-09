class PaidFeatureModel {
  final String id;
  final String jumuiyaId;
  final String serviceId;
  final String startDate;
  final String endDate;
  final String price;
  final bool active;
  final String tarehe;
  final String userName;
  final String paymentStatus;
  final PaidFeatureUser? user;
  final PaidFeatureService? service;

  PaidFeatureModel({
    required this.id,
    required this.jumuiyaId,
    required this.serviceId,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.active,
    required this.tarehe,
    required this.userName,
    required this.paymentStatus,
    this.user,
    this.service,
  });

  factory PaidFeatureModel.fromJson(Map<String, dynamic> json) {
    return PaidFeatureModel(
      id: json['id'].toString(),
      jumuiyaId: json['jumuiyaId'].toString(),
      serviceId: json['serviceId'].toString(),
      startDate: json['startDate'].toString(),
      endDate: json['endDate'].toString(),
      price: json['price'].toString(),
      active: json['active'] == true || json['active'] == 1,
      tarehe: json['tarehe'].toString(),
      userName: json['userName'].toString(),
      paymentStatus: json['paymentStatus'].toString(),
      user:
          json['user'] != null ? PaidFeatureUser.fromJson(json['user']) : null,
      service: json['service'] != null
          ? PaidFeatureService.fromJson(json['service'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jumuiyaId': jumuiyaId,
      'serviceId': serviceId,
      'startDate': startDate,
      'endDate': endDate,
      'price': price,
      'active': active,
      'tarehe': tarehe,
      'userName': userName,
      'paymentStatus': paymentStatus,
      'user': user?.toJson(),
      'service': service?.toJson(),
    };
  }
}

class PaidFeatureService {
  final String id;
  final String sname;
  final String sprice;
  final String spaymentType;
  final String forUserType;

  PaidFeatureService({
    required this.id,
    required this.sname,
    required this.sprice,
    required this.spaymentType,
    required this.forUserType,
  });

  factory PaidFeatureService.fromJson(Map<String, dynamic> json) {
    return PaidFeatureService(
      id: json['id'].toString(),
      sname: json['sname'].toString(),
      sprice: json['sprice'].toString(),
      spaymentType: json['spayment_type'].toString(),
      forUserType: json['spayment_type'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sname': sname,
      'sprice': sprice,
      'spaymentType': spaymentType,
      'forUserType': forUserType,
    };
  }
}

class PaidFeatureUser {
  final String id;
  final String userFullName;
  final String userName;
  final String phone;
  final String role;
  final String yearRegistered;
  final String createdAt;

  PaidFeatureUser({
    required this.id,
    required this.userFullName,
    required this.userName,
    required this.phone,
    required this.role,
    required this.yearRegistered,
    required this.createdAt,
  });

  factory PaidFeatureUser.fromJson(Map<String, dynamic> json) {
    return PaidFeatureUser(
      id: json['id'].toString(),
      userFullName: json['userFullName'].toString(),
      userName: json['userName'].toString(),
      phone: json['phone'].toString(),
      role: json['role'].toString(),
      yearRegistered: json['yearRegistered'].toString(),
      createdAt: json['createdAt'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userFullName': userFullName,
      'userName': userName,
      'phone': phone,
      'role': role,
      'yearRegistered': yearRegistered,
      'createdAt': createdAt,
    };
  }
}
