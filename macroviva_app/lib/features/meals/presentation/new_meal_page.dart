import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../foods/application/foods_providers.dart';
import '../../foods/data/food_model.dart';
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

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
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
                                'Escolha o alimento, informe a quantidade e salve no seu dia.',
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
                          labelText: 'Alimento',
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
                            : (value) => setState(() => _selectedFood = value),
                      ),
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
}
