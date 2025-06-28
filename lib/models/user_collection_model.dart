class UserCollectionResponse {
  final int statusCode;
  final String message;
  final List<UserCollection> response;

  UserCollectionResponse({
    required this.statusCode,
    required this.message,
    required this.response,
  });

  factory UserCollectionResponse.fromJson(Map<String, dynamic> json) {
    return UserCollectionResponse(
      statusCode: json['statusCode'],
      message: json['message'],
      response: List<UserCollection>.from(
        json['response'].map((x) => UserCollection.fromJson(x)),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'statusCode': statusCode,
        'message': message,
        'response': response.map((x) => x.toJson()).toList(),
      };
}

class UserCollection {
  final int id;
  final int amount;
  final User user;
  final ChurchYearEntity churchYearEntity;
  final String monthly;
  final String registeredBy;

  UserCollection({
    required this.id,
    required this.amount,
    required this.user,
    required this.churchYearEntity,
    required this.monthly,
    required this.registeredBy,
  });

  factory UserCollection.fromJson(Map<String, dynamic> json) {
    return UserCollection(
      id: json['id'],
      amount: json['amount'],
      user: User.fromJson(json['user']),
      churchYearEntity: ChurchYearEntity.fromJson(json['churchYearEntity']),
      monthly: json['monthly'],
      registeredBy: json['registeredBy'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'user': user.toJson(),
        'churchYearEntity': churchYearEntity.toJson(),
        'monthly': monthly,
        'registeredBy': registeredBy,
      };
}

class User {
  final int id;
  final String countryCode;
  final String userFullName;
  final String userName;
  final String phone;
  final String password;
  final String createdAt;
  final String yearRegistered;
  final String role;

  User({
    required this.id,
    required this.countryCode,
    required this.userFullName,
    required this.userName,
    required this.phone,
    required this.password,
    required this.createdAt,
    required this.yearRegistered,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      countryCode: json['countryCode'],
      userFullName: json['userFullName'],
      userName: json['userName'],
      phone: json['phone'],
      password: json['password'],
      createdAt: json['createdAt'],
      yearRegistered: json['yearRegistered'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'countryCode': countryCode,
        'userFullName': userFullName,
        'userName': userName,
        'phone': phone,
        'password': password,
        'createdAt': createdAt,
        'yearRegistered': yearRegistered,
        'role': role,
      };
}

class ChurchYearEntity {
  final int id;
  final String churchYear;
  final bool isActive;

  ChurchYearEntity({
    required this.id,
    required this.churchYear,
    required this.isActive,
  });

  factory ChurchYearEntity.fromJson(Map<String, dynamic> json) {
    return ChurchYearEntity(
      id: json['id'],
      churchYear: json['churchYear'],
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'churchYear': churchYear,
        'isActive': isActive,
      };
}
