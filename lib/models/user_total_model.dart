class UserTotalsResponse {
  final int statusCode;
  final String message;
  final List<TotalItem> response;

  UserTotalsResponse({
    required this.statusCode,
    required this.message,
    required this.response,
  });

  factory UserTotalsResponse.fromJson(Map<String, dynamic> json) {
    return UserTotalsResponse(
      statusCode: json['statusCode'],
      message: json['message'],
      response: (json['response'] as List).map((item) => TotalItem.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'response': response.map((item) => item.toJson()).toList(),
    };
  }
}

class TotalItem {
  final String name;
  final int total;

  TotalItem({
    required this.name,
    required this.total,
  });

  factory TotalItem.fromJson(Map<String, dynamic> json) {
    return TotalItem(
      name: json['name'],
      total: json['total'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'total': total,
    };
  }
}
