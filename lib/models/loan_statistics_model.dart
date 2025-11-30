class LoanStatisticsResponse {
  final String status;
  final String message;
  final LoanStatisticsData data;

  LoanStatisticsResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory LoanStatisticsResponse.fromJson(Map<String, dynamic> json) {
    return LoanStatisticsResponse(
      status: json['status'].toString(),
      message: json['message'] as String,
      data: LoanStatisticsData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.toJson(),
    };
  }
}

class LoanStatisticsData {
  final double totalLoanTaken;
  final double totalLoanRepaid;
  final double remainingLoan;

  LoanStatisticsData({
    required this.totalLoanTaken,
    required this.totalLoanRepaid,
    required this.remainingLoan,
  });

  factory LoanStatisticsData.fromJson(Map<String, dynamic> json) {
    return LoanStatisticsData(
      totalLoanTaken: _parseDouble(json['totalLoanTaken']),
      totalLoanRepaid: _parseDouble(json['totalLoanRepaid']),
      remainingLoan: _parseDouble(json['remainingLoan']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalLoanTaken': totalLoanTaken,
      'totalLoanRepaid': totalLoanRepaid,
      'remainingLoan': remainingLoan,
    };
  }
}
