class MacronutrientsModel {
  const MacronutrientsModel({
    required this.calories,
    required this.proteinGrams,
    required this.carbohydrateGrams,
    required this.fatGrams,
  });

  factory MacronutrientsModel.fromJson(Map<String, dynamic>? json) {
    return MacronutrientsModel(
      calories: _decimal(json?['calories']),
      proteinGrams: _decimal(json?['proteinGrams']),
      carbohydrateGrams: _decimal(json?['carbohydrateGrams']),
      fatGrams: _decimal(json?['fatGrams']),
    );
  }

  static const zero = MacronutrientsModel(
    calories: 0,
    proteinGrams: 0,
    carbohydrateGrams: 0,
    fatGrams: 0,
  );

  final double calories;
  final double proteinGrams;
  final double carbohydrateGrams;
  final double fatGrams;

  MacronutrientsModel operator +(MacronutrientsModel other) {
    return MacronutrientsModel(
      calories: calories + other.calories,
      proteinGrams: proteinGrams + other.proteinGrams,
      carbohydrateGrams: carbohydrateGrams + other.carbohydrateGrams,
      fatGrams: fatGrams + other.fatGrams,
    );
  }

  static double _decimal(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }
}
