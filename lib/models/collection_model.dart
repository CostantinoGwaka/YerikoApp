import 'package:jumuiya_yangu/models/auth_model.dart';

class ContributionResponseNew {
  final String status;
  final String message;
  final List<Contribution> data;

  ContributionResponseNew({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ContributionResponseNew.fromJson(Map<String, dynamic> json) {
    return ContributionResponseNew(
      status: json['status'],
      message: json['message'],
      data: (json['data'] as List).map((e) => Contribution.fromJson(e)).toList(),
    );
  }
}

class Contribution {
  final int id;
  final String amount;
  final String monthly;
  final String registeredBy;
  final String registeredDate;
  final User mtumiaji;
  final ChurchYear mwakaWaKanisa;

  Contribution({
    required this.id,
    required this.amount,
    required this.monthly,
    required this.registeredBy,
    required this.registeredDate,
    required this.mtumiaji,
    required this.mwakaWaKanisa,
  });

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      id: json['id'],
      amount: json['amount'],
      monthly: json['monthly'],
      registeredBy: json['registered_by'],
      registeredDate: json['registered_date'],
      mtumiaji: User.fromJson(json['mtumiaji']),
      mwakaWaKanisa: ChurchYear.fromJson(json['mwakaWaKanisa']),
    );
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
      churchYear: json['church_year'],
      isActive: json['is_active'],
    );
  }
}
