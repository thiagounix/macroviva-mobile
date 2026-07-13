import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../foods/application/foods_providers.dart';
import '../../foods/data/food_model.dart';
import '../../foods/presentation/widgets/food_portion_chips.dart';
import '../application/meal_photo_analysis_providers.dart';
import '../data/analyze_meal_photo_response.dart';
import '../data/confirm_meal_analysis_request.dart';

class MealAnalysisResultArgs {
  const MealAnalysisResultArgs({
    required this.analysis,
    required this.photoBytes,
    this.photoName,
  });

  final AnalyzeMealPhotoResponse analysis;
  final Uint8List photoBytes;
  final String? photoName;
}

class MealAnalysisResultPage extends ConsumerStatefulWidget {
  const MealAnalysisResultPage({super.key, required this.args});

  final MealAnalysisResultArgs args;

  @override
  ConsumerState<MealAnalysisResultPage> createState() =>
      _MealAnalysisResultPageState();
}

class _MealAnalysisResultPageState
    extends ConsumerState<MealAnalysisResultPage> {
  final _formKey = GlobalKey<FormState>();
  late final List<_EditableDetectedItem> _items;
  bool _initializedFoodSelection = false;

  @override
  void initState() {
    super.initState();
    _items = widget.args.analysis.items
        .map((item) => _EditableDetectedItem.fromDetectedItem(item))
        .toList();
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foods = ref.watch(foodsProvider(''));
    final confirmState = ref.watch(confirmMealAnalysisControllerProvider);
    final isConfirming = confirmState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisar análise'),
        leading: IconButton(
          onPressed: isConfirming ? null : () => context.go('/meal-photo'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: foods.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _CenteredMessage(
            message: 'Não foi possível carregar alimentos: $error',
            action: OutlinedButton.icon(
              onPressed: () => ref.invalidate(foodsProvider('')),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ),
          data: (foodItems) {
            _initializeFoodSelection(foodItems);

            if (_items.isEmpty) {
              return const _CenteredMessage(
                message: 'A análise não retornou itens para confirmar.',
              );
            }

            return Form(
              key: _formKey,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      _SelectedPhotoPreview(
                        photoBytes: widget.args.photoBytes,
                        photoName: widget.args.photoName,
                      ),
                      const SizedBox(height: 12),
                      const _MockAnalysisNotice(),
                      const SizedBox(height: 12),
                      const _ReviewInstruction(),
                      const SizedBox(height: 20),
                      Text(
                        'Itens detectados',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ..._items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DetectedItemCard(
                            item: item,
                            foods: foodItems,
                            enabled: !isConfirming,
                            onFoodChanged: (foodId) {
                              setState(() {
                                item.selectedFoodId = foodId;
                                item.selectedPortionGrams = null;
                              });
                            },
                            onPortionSelected: (portion) {
                              setState(() {
                                item.selectedPortionGrams = portion.grams;
                                item.gramsController.text = _formatGrams(
                                  portion.grams,
                                );
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _ConfirmMealBar(
        isConfirming: isConfirming,
        enabled: foods.when(
          data: (items) => items.isNotEmpty,
          error: (error, stackTrace) => false,
          loading: () => false,
        ),
        onConfirm: _confirm,
      ),
    );
  }

  void _initializeFoodSelection(List<FoodModel> foods) {
    if (_initializedFoodSelection) {
      return;
    }

    for (final item in _items) {
      final suggestedFoodId = item.detectedItem.suggestedFoodId;
      final suggestedFoodExists =
          suggestedFoodId != null &&
          foods.any((food) => food.id == suggestedFoodId);

      if (suggestedFoodExists) {
        item.selectedFoodId = suggestedFoodId;
        continue;
      }

      final normalizedSuggestedName = _normalize(
        item.detectedItem.suggestedFoodName,
      );
      final matchedFood = foods
          .where((food) => _normalize(food.name) == normalizedSuggestedName)
          .firstOrNull;
      item.selectedFoodId = matchedFood?.id;
    }

    _initializedFoodSelection = true;
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final invalidSelection = _items.any(
      (item) => item.selectedFoodId == null || item.selectedFoodId!.isEmpty,
    );

    if (invalidSelection) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Escolha um alimento para cada item detectado.'),
        ),
      );
      return;
    }

    final requestItems = <ConfirmMealAnalysisItemRequest>[];
    for (final item in _items) {
      final grams = _parseGrams(item.gramsController.text);
      if (grams == null || grams <= 0) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Informe gramas maiores que zero.')),
        );
        return;
      }

      requestItems.add(
        ConfirmMealAnalysisItemRequest(
          analysisItemId: item.detectedItem.analysisItemId,
          selectedFoodId: item.selectedFoodId!,
          grams: grams,
        ),
      );
    }

    try {
      await ref
          .read(confirmMealAnalysisControllerProvider.notifier)
          .confirm(
            widget.args.analysis.analysisId,
            ConfirmMealAnalysisRequest(
              mealType: 'Lunch',
              occurredAt: DateTime.now(),
              items: requestItems,
            ),
          );

      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('Refeição confirmada com sucesso.')),
      );
      context.go('/dashboard');
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Falha ao confirmar refeição: $error')),
      );
    }
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  static double? _parseGrams(String? value) {
    if (value == null) {
      return null;
    }

    return double.tryParse(value.replaceAll(',', '.'));
  }

  static String _formatGrams(double grams) {
    if (grams % 1 == 0) {
      return grams.toStringAsFixed(0);
    }

    return grams.toStringAsFixed(1);
  }
}

class _SelectedPhotoPreview extends StatelessWidget {
  const _SelectedPhotoPreview({required this.photoBytes, this.photoName});

  final Uint8List photoBytes;
  final String? photoName;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.memory(photoBytes, fit: BoxFit.cover),
          ),
          if (photoName != null && photoName!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                photoName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _MockAnalysisNotice extends StatelessWidget {
  const _MockAnalysisNotice();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: colorScheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Análise simulada para desenvolvimento. A IA real ainda não está ativa.',
                style: TextStyle(color: colorScheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewInstruction extends StatelessWidget {
  const _ReviewInstruction();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Revise os alimentos e as quantidades antes de confirmar.',
    );
  }
}

class _ConfirmMealBar extends StatelessWidget {
  const _ConfirmMealBar({
    required this.isConfirming,
    required this.enabled,
    required this.onConfirm,
  });

  final bool isConfirming;
  final bool enabled;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.center,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isConfirming || !enabled ? null : onConfirm,
                  icon: isConfirming
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    isConfirming ? 'Confirmando...' : 'Confirmar refeição',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetectedItemCard extends StatelessWidget {
  const _DetectedItemCard({
    required this.item,
    required this.foods,
    required this.enabled,
    required this.onFoodChanged,
    required this.onPortionSelected,
  });

  final _EditableDetectedItem item;
  final List<FoodModel> foods;
  final bool enabled;
  final ValueChanged<String?> onFoodChanged;
  final ValueChanged<FoodPortionModel> onPortionSelected;

  @override
  Widget build(BuildContext context) {
    final selectedFoodId = foods.any((food) => food.id == item.selectedFoodId)
        ? item.selectedFoodId
        : null;
    final selectedFood = foods
        .where((food) => food.id == selectedFoodId)
        .firstOrNull;
    final needsCarefulReview = _needsCarefulReview(
      item.detectedItem.confidenceLevel,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.detectedItem.suggestedFoodName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Confiança: ${item.detectedItem.confidenceScore.toStringAsFixed(2)} '
              '(${item.detectedItem.confidenceLevel})',
            ),
            if (needsCarefulReview) ...[
              const SizedBox(height: 8),
              const _CarefulReviewNotice(),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: item.gramsController,
              enabled: enabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Gramas',
                helperText: selectedFood?.portions.isNotEmpty ?? false
                    ? 'Escolha uma porção rápida ou ajuste manualmente.'
                    : null,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                final grams = MealAnalysisResultPageStateHelper.parseGrams(
                  value,
                );
                if (grams == null || grams <= 0) {
                  return 'Informe gramas maiores que zero.';
                }

                return null;
              },
            ),
            if (selectedFood?.portions.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Text(
                'Porção rápida',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              FoodPortionChips(
                portions: selectedFood!.portions,
                selectedGrams: item.selectedPortionGrams,
                enabled: enabled,
                onSelected: onPortionSelected,
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedFoodId,
              decoration: const InputDecoration(
                labelText: 'Alimento confirmado',
                border: OutlineInputBorder(),
              ),
              items: foods
                  .map(
                    (food) => DropdownMenuItem(
                      value: food.id,
                      child: Text(food.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: enabled ? onFoodChanged : null,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Escolha um alimento.';
                }

                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _needsCarefulReview(String confidenceLevel) {
    final normalized = confidenceLevel.trim().toLowerCase();

    return normalized == 'medium' ||
        normalized == 'low' ||
        normalized == '1' ||
        normalized == '2';
  }
}

class _CarefulReviewNotice extends StatelessWidget {
  const _CarefulReviewNotice();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.warning_amber_outlined, size: 18, color: colorScheme.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Confira este item com atenção antes de salvar.',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
      ],
    );
  }
}

class MealAnalysisResultPageStateHelper {
  const MealAnalysisResultPageStateHelper._();

  static double? parseGrams(String? value) {
    if (value == null) {
      return null;
    }

    return double.tryParse(value.replaceAll(',', '.'));
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class _EditableDetectedItem {
  _EditableDetectedItem({
    required this.detectedItem,
    required this.gramsController,
  });

  factory _EditableDetectedItem.fromDetectedItem(
    DetectedMealItemModel detectedItem,
  ) {
    return _EditableDetectedItem(
      detectedItem: detectedItem,
      gramsController: TextEditingController(
        text: _formatGrams(detectedItem.grams),
      ),
    );
  }

  final DetectedMealItemModel detectedItem;
  final TextEditingController gramsController;
  String? selectedFoodId;
  double? selectedPortionGrams;

  void dispose() {
    gramsController.dispose();
  }

  static String _formatGrams(double grams) {
    if (grams % 1 == 0) {
      return grams.toStringAsFixed(0);
    }

    return grams.toString();
  }
}
