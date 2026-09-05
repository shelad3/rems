class SubscriptionPlanModel {
  final String planId;
  final String name;
  final double price;
  final String billingPeriod;
  final List<String> features;
  final bool isPremium;
  final bool isRecommended;
  final bool isActive;

  SubscriptionPlanModel({
    required this.planId,
    required this.name,
    required this.price,
    this.billingPeriod = 'month',
    List<String>? features,
    this.isPremium = false,
    this.isRecommended = false,
    this.isActive = true,
  }) : features = features ?? [];

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'billingPeriod': billingPeriod,
        'features': features,
        'isPremium': isPremium,
        'isRecommended': isRecommended,
        'isActive': isActive,
      };

  factory SubscriptionPlanModel.fromMap(Map<String, dynamic> map, String id) {
    return SubscriptionPlanModel(
      planId: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      billingPeriod: map['billingPeriod'] ?? 'month',
      features: List<String>.from(map['features'] ?? []),
      isPremium: map['isPremium'] ?? false,
      isRecommended: map['isRecommended'] ?? false,
      isActive: map['isActive'] ?? true,
    );
  }
}