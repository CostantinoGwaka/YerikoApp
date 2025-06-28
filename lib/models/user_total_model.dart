class UserTotalsResponse {
  final String status;
  final String message;
  final int userId;
  final String churchYear;
  final int currentYearTotal;
  final int overallTotal;
  final int otherTotal;

  UserTotalsResponse({
    required this.status,
    required this.message,
    required this.userId,
    required this.churchYear,
    required this.currentYearTotal,
    required this.overallTotal,
    required this.otherTotal,
  });

  factory UserTotalsResponse.fromJson(Map<String, dynamic> json) {
    return UserTotalsResponse(
        status: json['status'],
        message: json['message'],
        userId: json['userId'],
        churchYear: json['churchYear'],
        currentYearTotal: json['currentYearTotal'],
        overallTotal: json['overallTotal'],
        otherTotal: json['otherTotal']);
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'userId': userId,
      'churchYear': churchYear,
      'currentYearTotal': currentYearTotal,
      'overallTotal': overallTotal,
      'otherTotal': otherTotal
    };
  }
}
