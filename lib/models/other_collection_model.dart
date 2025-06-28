class OtherCollectionResponse {
  final String status;
  final String message;
  final List<OtherCollection> data;

  OtherCollectionResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory OtherCollectionResponse.fromJson(Map<String, dynamic> json) {
    return OtherCollectionResponse(
      status: json['status'],
      message: json['message'],
      data: List<OtherCollection>.from(
        json['data'].map((item) => OtherCollection.fromJson(item)),
      ),
    );
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

  OtherCollection({
    required this.id,
    required this.amount,
    required this.monthly,
    required this.registeredBy,
    required this.registeredDate,
    required this.collectionType,
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
      collectionType: CollectionType.fromJson(json['collection_type']),
      user: User.fromJson(json['user']),
      churchYearEntity: ChurchYearEntity.fromJson(json['churchYearEntity']),
    );
  }
}

class CollectionType {
  final int id;
  final String collectionName;

  CollectionType({
    required this.id,
    required this.collectionName,
  });

  factory CollectionType.fromJson(Map<String, dynamic> json) {
    return CollectionType(
      id: json['id'],
      collectionName: json['collection_name'],
    );
  }
}

class User {
  final int id;
  final String userFullName;
  final String userName;
  final String phone;
  final String role;
  final String yearRegistered;

  User({
    required this.id,
    required this.userFullName,
    required this.userName,
    required this.phone,
    required this.role,
    required this.yearRegistered,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      userFullName: json['user_full_name'],
      userName: json['user_name'],
      phone: json['phone'],
      role: json['role'],
      yearRegistered: json['year_registered'],
    );
  }
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
}
