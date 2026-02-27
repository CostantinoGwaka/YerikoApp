import 'package:jumuiya_yangu/models/auth_model.dart';

class OtherCollectionResponse {
  final String status;
  final String message;
  final List<OtherCollection> data;

  OtherCollectionResponse(
      {required this.status, required this.message, required this.data});

  factory OtherCollectionResponse.fromJson(Map<String, dynamic> json) {
    return OtherCollectionResponse(
      status: json['status'],
      message: json['message'],
      data: List<OtherCollection>.from(
        json['data'].map((item) => OtherCollection.fromJson(item)),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

class OtherCollection {
  final int id;
  final String amount;
  final String monthly;
  final String registeredBy;
  final String registeredDate;
  final CollectionType collectionType;
  final User user;
  final ChurchYearEntity churchYearEntity;
  String total;

  OtherCollection(
      {required this.id,
      required this.amount,
      required this.monthly,
      required this.registeredBy,
      required this.registeredDate,
      required this.collectionType,
      required this.user,
      required this.churchYearEntity,
      this.total = '0'});

  factory OtherCollection.fromJson(Map<String, dynamic> json) {
    return OtherCollection(
      id: json['id'],
      amount: json['amount'],
      monthly: json['monthly'],
      registeredBy: json['registered_by'],
      registeredDate: json['registered_date'],
      collectionType: CollectionType.fromJson(json['collection_type']),
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
      'collection_type': collectionType.toJson(),
      'user': user.toJson(),
      'churchYearEntity': churchYearEntity.toJson(),
      'total': total,
    };
  }
}

class CollectionType {
  final int id;
  final String collectionName;
  final String? dateRegistered;
  final String? jumuiyaId;

  CollectionType({
    required this.id,
    required this.collectionName,
    this.dateRegistered,
    this.jumuiyaId,
  });

  factory CollectionType.fromJson(Map<String, dynamic> json) {
    return CollectionType(
      id: json['id'],
      collectionName: json['collection_name'],
      dateRegistered: json['date_registered'],
      jumuiyaId: json['jumuiya_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collection_name': collectionName,
      'date_registered': dateRegistered,
      'jumuiya_id': jumuiyaId,
    };
  }

  // ✅ override equality so DropdownButton can compare correctly
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionType &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ChurchYearEntity {
  final int id;
  final String churchYear;
  final bool isActive;

  ChurchYearEntity({
    required this.id,
    required this.churchYear,
    required this.isActive,
  });

  factory ChurchYearEntity.fromJson(Map<String, dynamic> json) {
    return ChurchYearEntity(
      id: json['id'],
      churchYear: json['churchYear'],
      isActive: json['isActive'] == true || json['isActive'] == 1,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'churchYear': churchYear,
      'isActive': isActive,
    };
  }
}
