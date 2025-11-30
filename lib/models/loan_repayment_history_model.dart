class LoanRepaymentHistoryResponse {
  final String status;
  final String message;
  final LoanDetail loan;
  final List<Repayment> repayments;
  final LoanStatistics statistics;

  LoanRepaymentHistoryResponse({
    required this.status,
    required this.message,
    required this.loan,
    required this.repayments,
    required this.statistics,
  });

  factory LoanRepaymentHistoryResponse.fromJson(Map<String, dynamic> json) {
    return LoanRepaymentHistoryResponse(
      status: json['status'].toString(),
      message: json['message'] as String,
      loan: LoanDetail.fromJson(json['loan'] as Map<String, dynamic>),
      repayments: (json['repayments'] as List<dynamic>)
          .map((repayment) =>
              Repayment.fromJson(repayment as Map<String, dynamic>))
          .toList(),
      statistics:
          LoanStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'loan': loan.toJson(),
      'repayments': repayments.map((r) => r.toJson()).toList(),
      'statistics': statistics.toJson(),
    };
  }
}

class LoanDetail {
  final dynamic id;
  final dynamic userId;
  final dynamic jumuiyaId;
  final String amount;
  final String interestRate;
  final String totalAmount;
  final String monthlyInstallment;
  final String status;
  final String loanType;
  final dynamic approvedBy;
  final String requestedAt;
  final String? approvedAt;

  LoanDetail({
    required this.id,
    required this.userId,
    required this.jumuiyaId,
    required this.amount,
    required this.interestRate,
    required this.totalAmount,
    required this.monthlyInstallment,
    required this.status,
    required this.loanType,
    this.approvedBy,
    required this.requestedAt,
    this.approvedAt,
  });

  factory LoanDetail.fromJson(Map<String, dynamic> json) {
    return LoanDetail(
      id: json['id'],
      userId: json['user_id'],
      jumuiyaId: json['jumuiya_id'],
      amount: json['amount'].toString(),
      interestRate: json['interest_rate'].toString(),
      totalAmount: json['total_amount'].toString(),
      monthlyInstallment: json['monthly_installment'].toString(),
      status: json['status'] as String,
      loanType: json['loan_type'] as String,
      approvedBy: json['approved_by'],
      requestedAt: json['requested_at'] as String,
      approvedAt: json['approved_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'jumuiya_id': jumuiyaId,
      'amount': amount,
      'interest_rate': interestRate,
      'total_amount': totalAmount,
      'monthly_installment': monthlyInstallment,
      'status': status,
      'loan_type': loanType,
      'approved_by': approvedBy,
      'requested_at': requestedAt,
      'approved_at': approvedAt,
    };
  }
}

class Repayment {
  final dynamic id;
  final dynamic loanId;
  final dynamic jumuiyaId;
  final String amount;
  final dynamic collectedBy;
  final String paidAt;

  Repayment({
    required this.id,
    required this.loanId,
    required this.jumuiyaId,
    required this.amount,
    required this.collectedBy,
    required this.paidAt,
  });

  factory Repayment.fromJson(Map<String, dynamic> json) {
    return Repayment(
      id: json['id'],
      loanId: json['loan_id'],
      jumuiyaId: json['jumuiya_id'],
      amount: json['amount'].toString(),
      collectedBy: json['collected_by'],
      paidAt: json['paid_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loan_id': loanId,
      'jumuiya_id': jumuiyaId,
      'amount': amount,
      'collected_by': collectedBy,
      'paid_at': paidAt,
    };
  }
}

class LoanStatistics {
  final double totalLoanTaken;
  final double totalLoanRepaid;
  final double remainingLoan;
  final double percentagePaid;
  final int numberOfPaymentsMade;
  final String? lastPaymentDate;
  final String? nextPaymentDate;
  final String loanStatus;

  LoanStatistics({
    required this.totalLoanTaken,
    required this.totalLoanRepaid,
    required this.remainingLoan,
    required this.percentagePaid,
    required this.numberOfPaymentsMade,
    this.lastPaymentDate,
    this.nextPaymentDate,
    required this.loanStatus,
  });

  factory LoanStatistics.fromJson(Map<String, dynamic> json) {
    return LoanStatistics(
      totalLoanTaken: _parseDouble(json['totalLoanTaken']),
      totalLoanRepaid: _parseDouble(json['totalLoanRepaid']),
      remainingLoan: _parseDouble(json['remainingLoan']),
      percentagePaid: _parseDouble(json['percentagePaid']),
      numberOfPaymentsMade: _parseInt(json['numberOfPaymentsMade']),
      lastPaymentDate: json['lastPaymentDate']?.toString(),
      nextPaymentDate: json['nextPaymentDate']?.toString(),
      loanStatus: json['loanStatus'] as String,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalLoanTaken': totalLoanTaken,
      'totalLoanRepaid': totalLoanRepaid,
      'remainingLoan': remainingLoan,
      'percentagePaid': percentagePaid,
      'numberOfPaymentsMade': numberOfPaymentsMade,
      'lastPaymentDate': lastPaymentDate,
      'nextPaymentDate': nextPaymentDate,
      'loanStatus': loanStatus,
    };
  }
}
