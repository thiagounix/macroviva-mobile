class ConfirmMealAnalysisRequest {
  const ConfirmMealAnalysisRequest({
    required this.mealType,
    required this.occurredAt,
    required this.items,
  });

  final String mealType;
  final DateTime occurredAt;
  final List<ConfirmMealAnalysisItemRequest> items;

  Map<String, dynamic> toJson() {
    return {
      'mealType': mealType,
      'occurredAt': occurredAt.toUtc().toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class ConfirmMealAnalysisItemRequest {
  const ConfirmMealAnalysisItemRequest({
    required this.analysisItemId,
    required this.selectedFoodId,
    required this.grams,
  });

  final String analysisItemId;
  final String selectedFoodId;
  final double grams;

  Map<String, dynamic> toJson() {
    return {
      'analysisItemId': analysisItemId,
      'selectedFoodId': selectedFoodId,
      'grams': grams,
    };
  }
}
