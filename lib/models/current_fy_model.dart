class CurrentChurchYearResponse {
  final int statusCode;
  final String message;
  final ChurchYear response;

  CurrentChurchYearResponse({
    required this.statusCode,
    required this.message,
    required this.response,
  });

  factory CurrentChurchYearResponse.fromJson(Map<String, dynamic> json) {
    return CurrentChurchYearResponse(
      statusCode: json['statusCode'],
      message: json['message'],
      response: ChurchYear.fromJson(json['response']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'response': response.toJson(),
    };
  }
}

class ChurchYear {
  final int id;
  final String churchYear;
  final bool isActive;

  ChurchYear({
    required this.id,
    required this.churchYear,
    required this.isActive,
  });

  factory ChurchYear.fromJson(Map<String, dynamic> json) {
    return ChurchYear(
      id: json['id'],
      churchYear: json['churchYear'],
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'churchYear': churchYear,
      'isActive': isActive,
    };
  }
}
