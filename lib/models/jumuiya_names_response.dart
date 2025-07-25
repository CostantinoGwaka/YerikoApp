class JumuiyaNamesResponse {
  final String status;
  final String message;
  final List<String> data;

  JumuiyaNamesResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory JumuiyaNamesResponse.fromJson(Map<String, dynamic> json) {
    return JumuiyaNamesResponse(
      status: json['status'] as String,
      message: json['message'] as String,
      data: List<String>.from(json['data']),
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        'data': data,
      };
}
