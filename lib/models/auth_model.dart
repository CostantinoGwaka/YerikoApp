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
  final int? id;
  final String? phone;
  final String? userFullName;
  final String? yearRegistered;
  final String? createdAt;
  final String? userName;
  final String? role;

  User({
    this.id,
    this.phone,
    this.userFullName,
    this.yearRegistered,
    this.createdAt,
    this.userName,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      phone: json['phone']?.toString(),
      userFullName: json['userFullName']?.toString(),
      yearRegistered: json['yearRegistered']?.toString(),
      createdAt: json['createdAt']?.toString(),
      userName: json['userName']?.toString(),
      role: json['role']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'userFullName': userFullName,
        'yearRegistered': yearRegistered,
        'createdAt': createdAt,
        'userName': userName,
        'role': role,
      };

  // ✅ This is the fix
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
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
      userFullName: json['userFullName']?.toString(),
      yearRegistered: json['yearRegistered']?.toString(),
      userName: json['userName']?.toString(),
      role: json['role']?.toString(),
    );
  }
}
