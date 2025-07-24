class PendingRequestsResponse {
  final String status;
  final String message;
  final List<PendingRequest> data;

  PendingRequestsResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory PendingRequestsResponse.fromJson(Map<String, dynamic> json) {
    return PendingRequestsResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: (json['data'] as List).map((requestJson) => PendingRequest.fromJson(requestJson)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((request) => request.toJson()).toList(),
    };
  }
}

class PendingRequest {
  final int requestId;
  final String status;
  final String associatedDate;
  final String registeredBy;
  final int userId;
  final String userFullName;
  final String phone;
  final String userName;
  final String location;
  final String gender;
  final String dobdate;
  final String martialstatus;
  final String role;
  final int jumuiyaId;
  final String jumuiyaName;

  PendingRequest({
    required this.requestId,
    required this.status,
    required this.associatedDate,
    required this.registeredBy,
    required this.userId,
    required this.userFullName,
    required this.phone,
    required this.userName,
    required this.location,
    required this.gender,
    required this.dobdate,
    required this.martialstatus,
    required this.role,
    required this.jumuiyaId,
    required this.jumuiyaName,
  });

  factory PendingRequest.fromJson(Map<String, dynamic> json) {
    return PendingRequest(
      requestId: json['request_id'] ?? 0,
      status: json['status'] ?? '',
      associatedDate: json['associated_date'] ?? '',
      registeredBy: json['registered_by'] ?? '',
      userId: json['user_id'] ?? 0,
      userFullName: json['userFullName'] ?? '',
      phone: json['phone'] ?? '',
      userName: json['userName'] ?? '',
      location: json['location'] ?? '',
      gender: json['gender'] ?? '',
      dobdate: json['dobdate'] ?? '',
      martialstatus: json['martialstatus'] ?? '',
      role: json['role'] ?? '',
      jumuiyaId: json['jumuiya_id'] ?? 0,
      jumuiyaName: json['jumuiya_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'status': status,
      'associated_date': associatedDate,
      'registered_by': registeredBy,
      'user_id': userId,
      'userFullName': userFullName,
      'phone': phone,
      'userName': userName,
      'location': location,
      'gender': gender,
      'dobdate': dobdate,
      'martialstatus': martialstatus,
      'role': role,
      'jumuiya_id': jumuiyaId,
      'jumuiya_name': jumuiyaName,
    };
  }
}
