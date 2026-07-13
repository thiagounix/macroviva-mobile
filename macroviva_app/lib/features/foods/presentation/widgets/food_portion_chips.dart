import 'package:flutter/material.dart';

import '../../data/food_model.dart';

class FoodPortionChips extends StatelessWidget {
  const FoodPortionChips({
    super.key,
    required this.portions,
    this.selectedGrams,
    this.onSelected,
    this.enabled = true,
  });

  final List<FoodPortionModel> portions;
  final double? selectedGrams;
  final ValueChanged<FoodPortionModel>? onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final availablePortions = portions
        .where((portion) => portion.grams > 0 && portion.label.isNotEmpty)
        .toList();

    if (availablePortions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availablePortions.map((portion) {
        final selected =
            selectedGrams != null &&
            (selectedGrams! - portion.grams).abs() < 0.01;
        final label = '${portion.label} - ${_formatGrams(portion.grams)}g';

        if (onSelected == null) {
          return Chip(
            label: Text(label),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          );
        }

        return ChoiceChip(
          selected: selected,
          onSelected: enabled ? (_) => onSelected!(portion) : null,
          label: Text(label),
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }

  static String _formatGrams(double grams) {
    if (grams % 1 == 0) {
      return grams.toStringAsFixed(0);
    }

    return grams.toStringAsFixed(1);
  }
}
