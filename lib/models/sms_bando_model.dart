class SmsBandoSubscription {
  final int? id;
  final String jumuiyaId;
  final String userId;
  final double tsh;
  final int smsNumber;
  final String paymentStatus;
  final String packageName;
  final String tarehe;

  SmsBandoSubscription({
    this.id,
    required this.jumuiyaId,
    required this.userId,
    required this.tsh,
    required this.smsNumber,
    required this.packageName,
    required this.paymentStatus,
    required this.tarehe,
  });

  factory SmsBandoSubscription.fromJson(Map<String, dynamic> json) {
    return SmsBandoSubscription(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      jumuiyaId: json['jumuiya_id'].toString(),
      userId: json['user_id'].toString(),
      tsh: double.parse(json['tsh'].toString()),
      smsNumber: int.parse(json['sms_number'].toString()),
      packageName: json['package_name'].toString(),
      paymentStatus: json['payment_status'].toString(),
      tarehe: json['tarehe'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id?.toString(),
      'jumuiya_id': jumuiyaId,
      'user_id': userId,
      'tsh': tsh.toString(),
      'sms_number': smsNumber.toString(),
      'package_name': packageName,
      'payment_status': paymentStatus,
      'tarehe': tarehe,
    };
  }

  SmsBandoSubscription copyWith({
    int? id,
    String? jumuiyaId,
    String? userId,
    double? tsh,
    int? smsNumber,
    String? paymentStatus,
    String? dates,
  }) {
    return SmsBandoSubscription(
      id: id ?? this.id,
      jumuiyaId: jumuiyaId ?? this.jumuiyaId,
      userId: userId ?? this.userId,
      tsh: tsh ?? this.tsh,
      smsNumber: smsNumber ?? this.smsNumber,
      packageName: packageName,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      tarehe: tarehe,
    );
  }
}
