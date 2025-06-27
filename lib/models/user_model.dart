class UserDetails {
  final dynamic id;
  final String countryCode;
  final String userFullName;
  final String userName;
  final String phone;
  final String password;
  final String createdAt;
  final String role;

  UserDetails({
    required this.id,
    required this.countryCode,
    required this.userFullName,
    required this.userName,
    required this.phone,
    required this.password,
    required this.createdAt,
    required this.role,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      id: json['id'],
      countryCode: json['countryCode'],
      userFullName: json['userFullName'],
      userName: json['userName'],
      phone: json['phone'],
      password: json['password'],
      createdAt: json['createdAt'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'countryCode': countryCode,
      'userFullName': userFullName,
      'userName': userName,
      'phone': phone,
      'password': password,
      'createdAt': createdAt,
      'role': role,
    };
  }
}
