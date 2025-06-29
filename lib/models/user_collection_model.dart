import 'package:yeriko_app/models/auth_model.dart';

class CollectionResponse {
  final String status;
  final String message;
  final List<CollectionItem> data;

  CollectionResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory CollectionResponse.fromJson(Map<String, dynamic> json) {
    return CollectionResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)?.map((e) => CollectionItem.fromJson(e)).toList() ?? [],
    );
  }
}

class CollectionItem {
  final int id;
  final String amount;
  final String monthly;
  final String registeredBy;
  final String registeredDate;
  final User user;
  final ChurchYear churchYearEntity;

  CollectionItem({
    required this.id,
    required this.amount,
    required this.monthly,
    required this.registeredBy,
    required this.registeredDate,
    required this.user,
    required this.churchYearEntity,
  });

  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    return CollectionItem(
      id: json['id'],
      amount: json['amount'],
      monthly: json['monthly'],
      registeredBy: json['registered_by'],
      registeredDate: json['registered_date'],
      user: User.fromJson(json['user']),
      churchYearEntity: ChurchYear.fromJson(json['churchYearEntity']),
    );
  }
}

class ChurchYear {
  final int id;
  final String churchYear;
  final bool isActive;

  ChurchYear({
    required this.id,
    required this.churchYear,
    required this.isActive,
  });

  factory ChurchYear.fromJson(Map<String, dynamic> json) {
    return ChurchYear(
      id: json['id'],
      churchYear: json['churchYear'],
      isActive: json['isActive'] == true || json['isActive'] == "1",
    );
  }
}
