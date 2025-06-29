class LoginResponse {
  final String status;
  final String message;
  final User user;

  LoginResponse({
    required this.status,
    required this.message,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      status: json['status'],
      message: json['message'],
      user: User.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        'user': user.toJson(),
      };
}

class User {
  final int id;
  final String phone;
  final String userFullName;
  final String yearRegistered;
  final String createdAt;
  final String userName;
  final String role;

  User({
    required this.id,
    required this.phone,
    required this.userFullName,
    required this.yearRegistered,
    required this.createdAt,
    required this.userName,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phone: json['phone'],
      userFullName: json['user_full_name'],
      yearRegistered: json['year_registered'],
      createdAt: json['createdAt'],
      userName: json['user_name'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'user_full_name': userFullName,
        'year_registered': yearRegistered,
        'createdAt': createdAt,
        'user_name': userName,
        'role': role,
      };
}

class UserModel {
  final int? id;
  final String? phone;
  final String? userFullName;
  final String? yearRegistered;
  final String? userName;
  final String? role;

  UserModel({
    this.id,
    this.phone,
    this.userFullName,
    this.yearRegistered,
    this.userName,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      phone: json['phone']?.toString(),
      userFullName: json['user_full_name']?.toString(),
      yearRegistered: json['year_registered']?.toString(),
      userName: json['user_name']?.toString(),
      role: json['role']?.toString(),
    );
  }
}
