import 'package:yeriko_app/models/auth_model.dart';

import 'church_time_table.dart';

class OtherCollection {
  final int id;
  final String amount;
  final String monthly;
  final String registeredBy;
  final String registeredDate;
  final String jumuiyaId;
  final String collectionTypeId;
  final User user;
  final ChurchYearEntity churchYearEntity;

  OtherCollection({
    required this.id,
    required this.amount,
    required this.monthly,
    required this.registeredBy,
    required this.registeredDate,
    required this.jumuiyaId,
    required this.collectionTypeId,
    required this.user,
    required this.churchYearEntity,
  });

  factory OtherCollection.fromJson(Map<String, dynamic> json) {
    return OtherCollection(
      id: json['id'],
      amount: json['amount'],
      monthly: json['monthly'],
      registeredBy: json['registered_by'],
      registeredDate: json['registered_date'],
      jumuiyaId: json['jumuiya_id'],
      collectionTypeId: json['collection_type_id'],
      user: User.fromJson(json['user']),
      churchYearEntity: ChurchYearEntity.fromJson(json['churchYearEntity']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'monthly': monthly,
      'registered_by': registeredBy,
      'registered_date': registeredDate,
      'jumuiya_id': jumuiyaId,
      'collection_type_id': collectionTypeId,
      'user': user.toJson(),
      'churchYearEntity': churchYearEntity.toJson(),
    };
  }
}
