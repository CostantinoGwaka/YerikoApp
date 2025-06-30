import 'package:yeriko_app/models/auth_model.dart';

class AllUsersResponse {
  final String status;
  final String message;
  final List<User> data;

  AllUsersResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory AllUsersResponse.fromJson(Map<String, dynamic> json) {
    return AllUsersResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: (json['data'] as List).map((userJson) => User.fromJson(userJson)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((user) => user.toJson()).toList(),
    };
  }
}
