class SmsBandoSubscription {
  final int? id;
  final String jumuiyaId;
  final String userId;
  final double tsh;
  final int smsNumber;
  final String paymentStatus;
  final String dates;

  SmsBandoSubscription({
    this.id,
    required this.jumuiyaId,
    required this.userId,
    required this.tsh,
    required this.smsNumber,
    required this.paymentStatus,
    required this.dates,
  });

  factory SmsBandoSubscription.fromJson(Map<String, dynamic> json) {
    return SmsBandoSubscription(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      jumuiyaId: json['jumuiya_id'].toString(),
      userId: json['user_id'].toString(),
      tsh: double.parse(json['tsh'].toString()),
      smsNumber: int.parse(json['sms_number'].toString()),
      paymentStatus: json['payment_status'].toString(),
      dates: json['dates'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id?.toString(),
      'jumuiya_id': jumuiyaId,
      'user_id': userId,
      'tsh': tsh.toString(),
      'sms_number': smsNumber.toString(),
      'payment_status': paymentStatus,
      'dates': dates,
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
      paymentStatus: paymentStatus ?? this.paymentStatus,
      dates: dates ?? this.dates,
    );
  }
}
