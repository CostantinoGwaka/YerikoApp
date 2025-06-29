import 'package:yeriko_app/models/auth_model.dart';

class ChurchTimeTableResponse {
  final String? status;
  final String? message;
  final List<ChurchTimeTable>? data;

  ChurchTimeTableResponse({
    this.status,
    this.message,
    this.data,
  });

  factory ChurchTimeTableResponse.fromJson(Map<String, dynamic> json) {
    return ChurchTimeTableResponse(
      status: json['status']?.toString(),
      message: json['message']?.toString(),
      data: (json['data'] as List?)?.map((e) => ChurchTimeTable.fromJson(e)).toList(),
    );
  }
}

class ChurchTimeTable {
  final int id;
  final String? datePrayer;
  final String? latId;
  final String? longId;
  final String? location;
  final String? message;
  final String? registeredBy;
  final String? createdAt;
  final User? user;
  final ChurchYearEntity? churchYearEntity;

  ChurchTimeTable({
    required this.id,
    this.datePrayer,
    this.latId,
    this.longId,
    this.location,
    this.message,
    this.registeredBy,
    this.createdAt,
    this.user,
    this.churchYearEntity,
  });

  factory ChurchTimeTable.fromJson(Map<String, dynamic> json) {
    print(json['user']);
    return ChurchTimeTable(
      id: json['id'],
      datePrayer: json['datePrayer'],
      latId: json['latId'],
      longId: json['longId'],
      location: json['location'],
      message: json['message'],
      registeredBy: json['registeredBy'],
      createdAt: json['createdAt'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      churchYearEntity: json['churchYearEntity'] != null ? ChurchYearEntity.fromJson(json['churchYearEntity']) : null,
    );
  }
}

class ChurchYearEntity {
  final int? id;
  final String? churchYear;
  final bool? isActive;

  ChurchYearEntity({
    this.id,
    this.churchYear,
    this.isActive,
  });

  factory ChurchYearEntity.fromJson(Map<String, dynamic> json) {
    return ChurchYearEntity(
      id: json['id'],
      churchYear: json['churchYear'],
      isActive: json['isActive'],
    );
  }
}
