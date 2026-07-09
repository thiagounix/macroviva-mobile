import 'package:flutter/material.dart';

import '../../../meals/data/meal_model.dart';

class MealPeriodCard extends StatelessWidget {
  const MealPeriodCard({
    super.key,
    required this.title,
    required this.icon,
    required this.meals,
  });

  final String title;
  final IconData icon;
  final List<MealModel> meals;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final calories = meals.fold<double>(
      0,
      (current, meal) => current + meal.totalMacronutrients.calories,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            child: Icon(icon, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (meals.isNotEmpty)
                      Text(
                        '${calories.toStringAsFixed(0)} kcal',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (meals.isEmpty)
                  Text(
                    'Ainda não registrado',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  ...meals.map(
                    (meal) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _MealLine(meal: meal),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealLine extends StatelessWidget {
  const _MealLine({required this.meal});

  final MealModel meal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final foodNames = meal.items.isEmpty
        ? 'Itens registrados'
        : meal.items.take(2).map((item) => item.foodName).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          foodNames,
          style: textTheme.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${meal.items.length} itens · ${meal.totalMacronutrients.proteinGrams.toStringAsFixed(0)}g proteína',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}
