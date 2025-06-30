class CollectionType {
  final int id;
  final String collectionName;
  final String dateRegistered;
  final String jumuiyaId;

  CollectionType({
    required this.id,
    required this.collectionName,
    required this.dateRegistered,
    required this.jumuiyaId,
  });

  factory CollectionType.fromJson(Map<String, dynamic> json) {
    return CollectionType(
      id: json['id'],
      collectionName: json['collection_name'],
      dateRegistered: json['date_registered'],
      jumuiyaId: json['jumuiya_id'],
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
}

class CollectionTypeResponse {
  final String status;
  final String message;
  final List<CollectionType> data;

  CollectionTypeResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory CollectionTypeResponse.fromJson(Map<String, dynamic> json) {
    var list = (json['data'] as List).map((item) => CollectionType.fromJson(item)).toList();

    return CollectionTypeResponse(
      status: json['status'],
      message: json['message'],
      data: list,
    );
  }
}
