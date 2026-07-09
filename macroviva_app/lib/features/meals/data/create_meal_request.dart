class CreateMealRequest {
  const CreateMealRequest({
    required this.mealType,
    required this.occurredAt,
    required this.items,
  });

  final String mealType;
  final DateTime occurredAt;
  final List<CreateMealItemRequest> items;

  Map<String, dynamic> toJson() {
    return {
      'mealType': mealType,
      'occurredAt': occurredAt.toUtc().toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class CreateMealItemRequest {
  const CreateMealItemRequest({required this.foodId, required this.grams});

  final String foodId;
  final double grams;

  Map<String, dynamic> toJson() {
    return {'foodId': foodId, 'grams': grams};
  }
}
