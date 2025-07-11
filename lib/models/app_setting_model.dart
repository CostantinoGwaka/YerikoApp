class AppVersion {
  final int id;
  final String appVersion;
  final String appBuild;
  final String dateTime;
  final String lockStatus;

  AppVersion({
    required this.id,
    required this.appVersion,
    required this.appBuild,
    required this.dateTime,
    required this.lockStatus,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      id: json['id'],
      appVersion: json['appVersion'],
      appBuild: json['appBuild'],
      dateTime: json['dateTime'],
      lockStatus: json['lockStatus'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appVersion': appVersion,
      'appBuild': appBuild,
      'dateTime': dateTime,
      'lockStatus': lockStatus,
    };
  }
}
