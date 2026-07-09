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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  labelText: 'Buscar alimento',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: (value) {
                  setState(() => _searchQuery = value.trim());
                },
              ),
            ),
            Expanded(
              child: foods.when(
                loading: () =>
                    const AppLoadingView(message: 'Carregando alimentos...'),
                error: (error, stackTrace) => AppErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(foodsProvider(_searchQuery)),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(
                      child: Text('Nenhum alimento encontrado.'),
                    );
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
    );
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({required this.food});

  final FoodModel food;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.rice_bowl),
        title: Text(food.name),
        subtitle: Text(
          '${food.category} - ${food.nutritionPer100g.calories.toStringAsFixed(0)} kcal / 100g\n'
          'P ${food.nutritionPer100g.proteinGrams.toStringAsFixed(1)}g '
          'C ${food.nutritionPer100g.carbohydrateGrams.toStringAsFixed(1)}g '
          'G ${food.nutritionPer100g.fatGrams.toStringAsFixed(1)}g',
        ),
      ),
    );
  }
}
