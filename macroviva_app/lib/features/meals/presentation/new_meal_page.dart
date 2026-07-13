import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../foods/application/foods_providers.dart';
import '../../foods/data/food_model.dart';
import '../../foods/presentation/widgets/food_portion_chips.dart';
import '../application/meals_providers.dart';
import '../data/create_meal_request.dart';

class NewMealPage extends ConsumerStatefulWidget {
  const NewMealPage({super.key});

  @override
  ConsumerState<NewMealPage> createState() => _NewMealPageState();
}

class _NewMealPageState extends ConsumerState<NewMealPage> {
  final _formKey = GlobalKey<FormState>();
  final _gramsController = TextEditingController(text: '100');

  FoodModel? _selectedFood;
  String _mealType = 'Lunch';
  double? _selectedPortionGrams;

  @override
  void initState() {
    super.initState();
    _gramsController.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _gramsController.removeListener(_refreshPreview);
    _gramsController.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final foods = ref.watch(foodsProvider(''));
    final createState = ref.watch(createMealControllerProvider);
    final isSaving = createState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova refeição'),
        leading: IconButton(
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: foods.when(
          loading: () =>
              const AppLoadingView(message: 'Carregando alimentos...'),
          error: (error, stackTrace) => AppErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(foodsProvider('')),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Cadastre alimentos no backend antes de criar refeições.',
                  ),
                ),
              );
            }

            _selectedFood ??= items.first;

            return Form(
              key: _formKey,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Refeição manual',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Escolha o alimento e ajuste os gramas. O MacroViva calcula os macros com base nos alimentos selecionados.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _mealType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo da refeição',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Breakfast',
                            child: Text('Café da manhã'),
                          ),
                          DropdownMenuItem(
                            value: 'Lunch',
                            child: Text('Almoço'),
                          ),
                          DropdownMenuItem(
                            value: 'Dinner',
                            child: Text('Jantar'),
                          ),
                          DropdownMenuItem(
                            value: 'Snack',
                            child: Text('Lanche'),
                          ),
                          DropdownMenuItem(
                            value: 'PreWorkout',
                            child: Text('Pré-treino'),
                          ),
                          DropdownMenuItem(
                            value: 'PostWorkout',
                            child: Text('Pós-treino'),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Outro'),
                          ),
                        ],
                        onChanged: isSaving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _mealType = value);
                                }
                              },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<FoodModel>(
                        initialValue: _selectedFood,
                        decoration: const InputDecoration(
                          labelText: 'Busque na base nutricional',
                          helperText: 'Escolha o alimento e ajuste os gramas',
                          border: OutlineInputBorder(),
                        ),
                        items: items
                            .map(
                              (food) => DropdownMenuItem(
                                value: food,
                                child: Text(
                                  food.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (value) => setState(() {
                                _selectedFood = value;
                                _selectedPortionGrams = null;
                              }),
                      ),
                      if (_selectedFood?.portions.isNotEmpty ?? false) ...[
                        const SizedBox(height: 12),
                        _QuickPortionSection(
                          portions: _selectedFood!.portions,
                          selectedGrams: _selectedPortionGrams,
                          enabled: !isSaving,
                          onSelected: (portion) {
                            setState(() {
                              _selectedPortionGrams = portion.grams;
                              _gramsController.text = _formatGrams(
                                portion.grams,
                              );
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _gramsController,
                        enabled: !isSaving,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Gramas',
                          hintText: 'Ex.: 100 ou 100,5',
                          helperText:
                              'Use vírgula ou ponto. Ex.: 100,5 ou 100.5',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final grams = _parseGrams(value);
                          if (grams == null || grams <= 0) {
                            return 'Informe gramas maiores que zero.';
                          }

                          return null;
                        },
                      ),
                      if (_selectedFood != null) ...[
                        const SizedBox(height: 12),
                        _SelectedFoodMacroPreview(
                          food: _selectedFood!,
                          grams: _parseGrams(_gramsController.text),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: isSaving ? null : () => _submit(context),
                        icon: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          isSaving ? 'Salvando...' : 'Salvar refeição',
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
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedFood = _selectedFood;
    final grams = _parseGrams(_gramsController.text);

    if (selectedFood == null || grams == null) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      await ref
          .read(createMealControllerProvider.notifier)
          .createMeal(
            CreateMealRequest(
              mealType: _mealType,
              occurredAt: DateTime.now(),
              items: [
                CreateMealItemRequest(foodId: selectedFood.id, grams: grams),
              ],
            ),
          );

      messenger.showSnackBar(
        const SnackBar(content: Text('Refeição criada com sucesso.')),
      );
      router.go('/dashboard');
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Falha ao criar refeição: $error')),
      );
    }
  }

  double? _parseGrams(String? value) {
    if (value == null) {
      return null;
    }

    return double.tryParse(value.replaceAll(',', '.'));
  }

  String _formatGrams(double grams) {
    if (grams % 1 == 0) {
      return grams.toStringAsFixed(0);
    }

    return grams.toStringAsFixed(1);
  }
}

class _QuickPortionSection extends StatelessWidget {
  const _QuickPortionSection({
    required this.portions,
    required this.selectedGrams,
    required this.enabled,
    required this.onSelected,
  });

  final List<FoodPortionModel> portions;
  final double? selectedGrams;
  final bool enabled;
  final ValueChanged<FoodPortionModel> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escolha uma porção rápida',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Toque em P, M ou G para preencher os gramas automaticamente. Você ainda pode ajustar manualmente.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FoodPortionChips(
              portions: portions,
              selectedGrams: selectedGrams,
              enabled: enabled,
              onSelected: onSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedFoodMacroPreview extends StatelessWidget {
  const _SelectedFoodMacroPreview({required this.food, required this.grams});

  final FoodModel food;
  final double? grams;

  @override
  Widget build(BuildContext context) {
    final effectiveGrams = grams == null || grams! <= 0 ? 100.0 : grams!;
    final factor = effectiveGrams / 100;
    final nutrition = food.nutritionPer100g;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Prévia pela base nutricional',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              food.name,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PreviewChip(
                  label:
                      '${(nutrition.calories * factor).toStringAsFixed(0)} kcal',
                ),
                _PreviewChip(
                  label:
                      'P ${(nutrition.proteinGrams * factor).toStringAsFixed(1)}g',
                ),
                _PreviewChip(
                  label:
                      'C ${(nutrition.carbohydrateGrams * factor).toStringAsFixed(1)}g',
                ),
                _PreviewChip(
                  label:
                      'G ${(nutrition.fatGrams * factor).toStringAsFixed(1)}g',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}
