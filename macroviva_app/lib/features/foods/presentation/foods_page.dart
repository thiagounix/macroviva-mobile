import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../application/foods_providers.dart';
import '../data/food_model.dart';

class FoodsPage extends ConsumerStatefulWidget {
  const FoodsPage({super.key});

  @override
  ConsumerState<FoodsPage> createState() => _FoodsPageState();
}

class _FoodsPageState extends ConsumerState<FoodsPage> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foods = ref.watch(foodsProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alimentos'),
        leading: IconButton(
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => ref.invalidate(foodsProvider(_searchQuery)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          labelText: 'Buscar alimento',
                          hintText: 'Ex.: arroz, frango, banana',
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) {
                          setState(() => _searchQuery = value.trim());
                        },
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: foods.when(
                    loading: () => const AppLoadingView(
                      message: 'Carregando alimentos...',
                    ),
                    error: (error, stackTrace) => AppErrorView(
                      message: error.toString(),
                      onRetry: () =>
                          ref.invalidate(foodsProvider(_searchQuery)),
                    ),
                    data: (items) {
                      if (items.isEmpty) {
                        return const _EmptyFoods();
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(foodsProvider(_searchQuery));
                          await ref.read(foodsProvider(_searchQuery).future);
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemBuilder: (context, index) {
                            return _FoodTile(food: items[index]);
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemCount: items.length,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({required this.food});

  final FoodModel food;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                  child: const Icon(Icons.rice_bowl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (food.category.isNotEmpty) Text(food.category),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MacroChip(
                  label:
                      '${food.nutritionPer100g.calories.toStringAsFixed(0)} kcal',
                ),
                _MacroChip(
                  label:
                      'P ${food.nutritionPer100g.proteinGrams.toStringAsFixed(1)}g',
                ),
                _MacroChip(
                  label:
                      'C ${food.nutritionPer100g.carbohydrateGrams.toStringAsFixed(1)}g',
                ),
                _MacroChip(
                  label:
                      'G ${food.nutritionPer100g.fatGrams.toStringAsFixed(1)}g',
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Valores por 100g',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({required this.label});

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

class _EmptyFoods extends StatelessWidget {
  const _EmptyFoods();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off),
                SizedBox(height: 12),
                Text('Nenhum alimento encontrado.'),
                SizedBox(height: 4),
                Text(
                  'Tente outro termo ou confirme se o backend foi populado com seed.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
