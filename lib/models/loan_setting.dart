class LoanSetting {
  final dynamic id;
  final dynamic jumuiyaId;
  final double interestRate;
  final double? multiplier;
  final double? percentage;
  final dynamic maxPeriodMonths;

  LoanSetting({
    this.id,
    required this.jumuiyaId,
    required this.interestRate,
    this.multiplier,
    this.percentage,
    required this.maxPeriodMonths,
  });

  factory LoanSetting.fromJson(Map<String, dynamic> json) {
    return LoanSetting(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      jumuiyaId: int.parse(json['jumuiya_id'].toString()),
      interestRate: double.parse(json['interest_rate'].toString()),
      multiplier: json['multiplier'] != null
          ? double.tryParse(json['multiplier'].toString())
          : null,
      percentage: json['percentage'] != null
          ? double.tryParse(json['percentage'].toString())
          : null,
      maxPeriodMonths: int.parse(json['max_period_months'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'jumuiya_id': jumuiyaId,
      'interest_rate': interestRate,
      'multiplier': multiplier,
      'percentage': percentage,
      'max_period_months': maxPeriodMonths,
    };
  }

  LoanSetting copyWith({
    int? id,
    int? jumuiyaId,
    double? interestRate,
    double? multiplier,
    double? percentage,
    int? maxPeriodMonths,
  }) {
    return LoanSetting(
      id: id ?? this.id,
      jumuiyaId: jumuiyaId ?? this.jumuiyaId,
      interestRate: interestRate ?? this.interestRate,
      multiplier: multiplier ?? this.multiplier,
      percentage: percentage ?? this.percentage,
      maxPeriodMonths: maxPeriodMonths ?? this.maxPeriodMonths,
    );
  }
}
