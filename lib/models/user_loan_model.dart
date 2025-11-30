class UserLoansResponse {
  final dynamic status;
  final String message;
  final List<UserLoan> data;

  UserLoansResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory UserLoansResponse.fromJson(Map<String, dynamic> json) {
    return UserLoansResponse(
      status: json['status'],
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>)
          .map((loan) => UserLoan.fromJson(loan as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((loan) => loan.toJson()).toList(),
    };
  }
}

class UserLoan {
  final dynamic id;
  final String amount;
  final String interestRate;
  final String totalAmount;
  final String monthlyInstallment;
  final String status;
  final String loanType;
  final String? approvedBy;
  final String requestedAt;
  final String? approvedAt;
  final LoanJumuiya jumuiya;
  final LoanUser user;

  UserLoan({
    required this.id,
    required this.amount,
    required this.interestRate,
    required this.totalAmount,
    required this.monthlyInstallment,
    required this.status,
    required this.loanType,
    this.approvedBy,
    required this.requestedAt,
    this.approvedAt,
    required this.jumuiya,
    required this.user,
  });

  factory UserLoan.fromJson(Map<String, dynamic> json) {
    return UserLoan(
      id: json['id'],
      amount: json['amount'].toString(),
      interestRate: json['interest_rate'].toString(),
      totalAmount: json['total_amount'].toString(),
      monthlyInstallment: json['monthly_installment'].toString(),
      status: json['status'] as String,
      loanType: json['loan_type'] as String,
      approvedBy: json['approved_by']?.toString(),
      requestedAt: json['requested_at'] as String,
      approvedAt: json['approved_at']?.toString(),
      jumuiya: LoanJumuiya.fromJson(json['jumuiya'] as Map<String, dynamic>),
      user: LoanUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'interest_rate': interestRate,
      'total_amount': totalAmount,
      'monthly_installment': monthlyInstallment,
      'status': status,
      'loan_type': loanType,
      'approved_by': approvedBy,
      'requested_at': requestedAt,
      'approved_at': approvedAt,
      'jumuiya': jumuiya.toJson(),
      'user': user.toJson(),
    };
  }
}

class LoanJumuiya {
  final dynamic id;
  final String name;

  LoanJumuiya({
    required this.id,
    required this.name,
  });

  factory LoanJumuiya.fromJson(Map<String, dynamic> json) {
    return LoanJumuiya(
      id: json['id'],
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class LoanUser {
  final dynamic id;
  final String name;
  final String phone;
  final String username;
  final String role;

  LoanUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.username,
    required this.role,
  });

  factory LoanUser.fromJson(Map<String, dynamic> json) {
    return LoanUser(
      id: json['id'],
      name: json['name'] as String,
      phone: json['phone'] as String,
      username: json['username'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'username': username,
      'role': role,
    };
  }
}
