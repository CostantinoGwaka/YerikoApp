class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final bool isActive;
  final List<String> features;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isActive,
    required this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      isActive: json['is_active'] == 1,
      features: List<String>.from(json['features']),
    );
  }
}

class JumuiyaSubscription {
  final String id;
  final String jumuiyaId;
  final bool isPremium;
  final DateTime expiryDate;

  JumuiyaSubscription({
    required this.id,
    required this.jumuiyaId,
    required this.isPremium,
    required this.expiryDate,
  });

  factory JumuiyaSubscription.fromJson(Map<String, dynamic> json) {
    return JumuiyaSubscription(
      id: json['id'],
      jumuiyaId: json['jumuiya_id'],
      isPremium: json['is_premium'] == 1,
      expiryDate: DateTime.parse(json['expiry_date']),
    );
  }

  bool get isActive => isPremium && expiryDate.isAfter(DateTime.now());
}
