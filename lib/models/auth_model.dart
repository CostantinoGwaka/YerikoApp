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
  final String? location; // Optional field, not used in the current context
  final String? gender;
  final String? dobdate;
  final String? martialstatus;
  final String? role;
  // ignore: non_constant_identifier_names
  final dynamic jumuiya_id; // Optional field, not used in the current context

  User({
    this.id,
    this.phone,
    this.userFullName,
    this.yearRegistered,
    this.createdAt,
    this.userName,
    this.location,
    this.gender,
    this.dobdate,
    this.martialstatus,
    this.role,
    // ignore: non_constant_identifier_names
    this.jumuiya_id, // Optional field, not used in the current contex
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      phone: json['phone']?.toString(),
      userFullName: json['userFullName']?.toString(),
      yearRegistered: json['yearRegistered']?.toString(),
      createdAt: json['createdAt']?.toString(),
      userName: json['userName']?.toString(),
      location: json['location']?.toString(), // Optional field, not used in the current context
      gender: json['gender']?.toString(), // Optional field, not used in the current context
      dobdate: json['dobdate']?.toString(), // Optional field, not used in the current context
      martialstatus: json['martialstatus']?.toString(), //
      role: json['role']?.toString(),
      jumuiya_id: json['jumuiya_id']?.toString(), // Optional field, not used in the current context
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'userFullName': userFullName,
        'yearRegistered': yearRegistered,
        'createdAt': createdAt,
        'userName': userName,
        'location': location, // Optional field, not used in the current context
        'gender': gender,
        'dobdate': dobdate, // Optional field, not used in the current context
        'martialstatus': martialstatus, // Optional field, not used in the current context
        'role': role,
        'jumuiya_id': jumuiya_id, // Optional field, not used in the current context
      };

  // ✅ This is the fix
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
