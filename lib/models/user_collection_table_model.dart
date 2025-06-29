class UserMonthlyCollectionResponse {
  final String status;
  final String message;
  final List<UserMonthlyCollection> data;

  UserMonthlyCollectionResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory UserMonthlyCollectionResponse.fromJson(Map<String, dynamic> json) {
    return UserMonthlyCollectionResponse(
      status: json['status'] as String,
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>)
          .map((e) => UserMonthlyCollection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        'data': data.map((e) => e.toJson()).toList(),
      };
}

class UserMonthlyCollection {
  final int userId;
  final String userFullName;
  final List<String> monthsCollected;

  UserMonthlyCollection({
    required this.userId,
    required this.userFullName,
    required this.monthsCollected,
  });

  factory UserMonthlyCollection.fromJson(Map<String, dynamic> json) {
    return UserMonthlyCollection(
      userId: json['user_id'] as int,
      userFullName: json['userFullName'] as String,
      monthsCollected: List<String>.from(json['months_collected'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'userFullName': userFullName,
        'months_collected': monthsCollected,
      };
}
