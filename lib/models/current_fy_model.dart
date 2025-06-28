class ActiveChurchYearResponse {
  final String status;
  final String message;
  final ChurchYear data;

  ActiveChurchYearResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ActiveChurchYearResponse.fromJson(Map<String, dynamic> json) {
    return ActiveChurchYearResponse(
      status: json['status'],
      message: json['message'],
      data: ChurchYear.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        'data': data.toJson(),
      };
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
      isActive: json['isActive'].toString() == "1", // convert "1"/"0" to true/false
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'churchYear': churchYear,
        'isActive': isActive ? "1" : "0",
      };
}
