import '../../../core/models/macronutrients_model.dart';

class FoodModel {
  const FoodModel({
    required this.id,
    required this.name,
    required this.locale,
    required this.category,
    required this.nutritionPer100g,
    required this.isSupplement,
  });

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Alimento sem nome',
      locale: _asText(json['locale']),
      category: _asText(json['category']),
      nutritionPer100g: MacronutrientsModel.fromJson(
        json['nutritionPer100g'] as Map<String, dynamic>?,
      ),
      isSupplement: json['isSupplement'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final String locale;
  final String category;
  final MacronutrientsModel nutritionPer100g;
  final bool isSupplement;

  static String _asText(Object? value) {
    if (value == null) {
      return '';
    }

    return value.toString();
  }
}

class FoodSearchResponse {
  const FoodSearchResponse({required this.foods});

  factory FoodSearchResponse.fromJson(Map<String, dynamic> json) {
    final items = json['foods'];

    if (items is! List) {
      return const FoodSearchResponse(foods: []);
    }

    return FoodSearchResponse(
      foods: items
          .whereType<Map<String, dynamic>>()
          .map(FoodModel.fromJson)
          .toList(),
    );
  }

  final List<FoodModel> foods;
}
