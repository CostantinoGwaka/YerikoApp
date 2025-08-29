class SmsBandoUsedModel {
  final int totalWaliotumiwa;
  final int count;
  final String message;
  final int status;

  SmsBandoUsedModel({
    required this.totalWaliotumiwa,
    required this.count,
    required this.message,
    required this.status,
  });

  factory SmsBandoUsedModel.fromJson(Map<String, dynamic> json) {
    return SmsBandoUsedModel(
      totalWaliotumiwa: int.tryParse(json['total_waliotumiwa'].toString()) ?? 0,
      count: int.tryParse(json['count'].toString()) ?? 0,
      message: json['message']?.toString() ?? '',
      status: int.tryParse(json['status'].toString()) ?? 0,
    );
  }
}
