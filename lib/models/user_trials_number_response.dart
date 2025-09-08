class UserTrialsNumberResponse {
  final String status;
  final String message;
  final List<UserTrialData> data;

  UserTrialsNumberResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory UserTrialsNumberResponse.fromJson(Map<String, dynamic> json) {
    return UserTrialsNumberResponse(
      status: json['status'],
      message: json['message'],
      data: (json['data'] as List)
          .map((item) => UserTrialData.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}

class UserTrialData {
  final String reportTrials;

  UserTrialData({
    required this.reportTrials,
  });

  factory UserTrialData.fromJson(Map<String, dynamic> json) {
    return UserTrialData(
      reportTrials: json['report_trials'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'report_trials': reportTrials,
    };
  }
}
