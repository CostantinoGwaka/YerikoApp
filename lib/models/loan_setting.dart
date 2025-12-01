class LoanSetting {
  final int? id;
  final String name;
  final double? minAmounts;
  final double? maxAmounts;
  final String shareSaving; // 'SHARE' or 'SAVING'
  final double? sharePrice;
  final dynamic jumuiyaId;
  final double interestRate;
  final double? multiplier;
  final double? percentage;
  final int maxPeriodMonths;

  LoanSetting({
    this.id,
    required this.name,
    this.minAmounts,
    this.maxAmounts,
    required this.shareSaving,
    this.sharePrice,
    required this.jumuiyaId,
    required this.interestRate,
    this.multiplier,
    this.percentage,
    required this.maxPeriodMonths,
  });

  factory LoanSetting.fromJson(Map<String, dynamic> json) {
    return LoanSetting(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      name: json['name'] ?? '',
      minAmounts: json['min_amounts'] != null
          ? double.tryParse(json['min_amounts'].toString())
          : null,
      maxAmounts: json['max_amounts'] != null
          ? double.tryParse(json['max_amounts'].toString())
          : null,
      shareSaving: json['share_saving'] ?? 'SAVING',
      sharePrice: json['share_price'] != null
          ? double.tryParse(json['share_price'].toString())
          : null,
      jumuiyaId: json['jumuiya_id'],
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
      'name': name,
      if (minAmounts != null) 'min_amounts': minAmounts,
      if (maxAmounts != null) 'max_amounts': maxAmounts,
      'share_saving': shareSaving,
      if (sharePrice != null) 'share_price': sharePrice,
      'jumuiya_id': jumuiyaId,
      'interest_rate': interestRate,
      if (multiplier != null) 'multiplier': multiplier,
      if (percentage != null) 'percentage': percentage,
      'max_period_months': maxPeriodMonths,
    };
  }
}
