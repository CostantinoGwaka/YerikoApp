class SmsBandoSummaryModel {
  final int id;
  final int jumuiyaId;
  final int userId;
  final int smsTotal;
  final String tarehe;

  SmsBandoSummaryModel({
    required this.id,
    required this.jumuiyaId,
    required this.userId,
    required this.smsTotal,
    required this.tarehe,
  });

  factory SmsBandoSummaryModel.fromJson(Map<String, dynamic> json) {
    return SmsBandoSummaryModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      jumuiyaId: int.tryParse(json['jumuiya_id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      smsTotal: int.tryParse(json['sms_total'].toString()) ?? 0,
      tarehe: json['tarehe']?.toString() ?? '',
    );
  }
}
