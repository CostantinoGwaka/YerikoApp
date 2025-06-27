import 'package:yeriko_app/models/user_model.dart';

class LoginResponseModel {
  final int statusCode;
  final String message;
  final String accessToken;
  final int loginTime;
  final int expirationDuration;
  final UserDetails userDetails;

  LoginResponseModel({
    required this.statusCode,
    required this.message,
    required this.accessToken,
    required this.loginTime,
    required this.expirationDuration,
    required this.userDetails,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      statusCode: json['statusCode'],
      message: json['message'],
      accessToken: json['accessToken'],
      loginTime: json['loginTime'],
      expirationDuration: json['expirationDuration'],
      userDetails: UserDetails.fromJson(json['userDetails']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'accessToken': accessToken,
      'loginTime': loginTime,
      'expirationDuration': expirationDuration,
      'userDetails': userDetails.toJson(),
    };
  }
}
