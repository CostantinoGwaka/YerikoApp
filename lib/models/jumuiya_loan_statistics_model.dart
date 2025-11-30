class JumuiyaLoanStatisticsResponse {
  final String status;
  final String message;
  final int jumuiyaId;
  final List<LoanStatistic> statistics;

  JumuiyaLoanStatisticsResponse({
    required this.status,
    required this.message,
    required this.jumuiyaId,
    required this.statistics,
  });

  factory JumuiyaLoanStatisticsResponse.fromJson(Map<String, dynamic> json) {
    return JumuiyaLoanStatisticsResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      jumuiyaId: json['jumuiya_id'] ?? 0,
      statistics: (json['statistics'] as List<dynamic>?)
              ?.map((e) => LoanStatistic.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class LoanStatistic {
  final int loanId;
  final double totalLoanTaken;
  final double totalLoanRepaid;
  final double remainingLoan;
  final double percentagePaid;
  final int numberOfPaymentsMade;
  final String loanStatus;

  LoanStatistic({
    required this.loanId,
    required this.totalLoanTaken,
    required this.totalLoanRepaid,
    required this.remainingLoan,
    required this.percentagePaid,
    required this.numberOfPaymentsMade,
    required this.loanStatus,
  });

  factory LoanStatistic.fromJson(Map<String, dynamic> json) {
    return LoanStatistic(
      loanId: json['loan_id'] ?? 0,
      totalLoanTaken: double.tryParse(json['totalLoanTaken'].toString()) ?? 0.0,
      totalLoanRepaid:
          double.tryParse(json['totalLoanRepaid'].toString()) ?? 0.0,
      remainingLoan: double.tryParse(json['remainingLoan'].toString()) ?? 0.0,
      percentagePaid: double.tryParse(json['percentagePaid'].toString()) ?? 0.0,
      numberOfPaymentsMade: json['numberOfPaymentsMade'] ?? 0,
      loanStatus: json['loanStatus'] ?? '',
    );
  }
}
