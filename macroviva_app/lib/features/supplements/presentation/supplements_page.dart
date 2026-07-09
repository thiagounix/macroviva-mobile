import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../application/supplements_providers.dart';
import '../data/supplement_model.dart';

class SupplementsPage extends ConsumerWidget {
  const SupplementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplements = ref.watch(supplementsProvider);
    final checkInState = ref.watch(supplementCheckInControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suplementos'),
        leading: IconButton(
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => ref.invalidate(supplementsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: supplements.when(
          loading: () =>
              const AppLoadingView(message: 'Carregando suplementos...'),
          error: (error, stackTrace) => AppErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(supplementsProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const _EmptySupplements();
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(supplementsProvider);
                await ref.read(supplementsProvider.future);
              },
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      return _SupplementTile(
                        supplement: items[index],
                        isCheckingIn: checkInState.isLoading,
                        onCheckIn: () => _checkIn(context, ref, items[index]),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemCount: items.length,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _checkIn(
    BuildContext context,
    WidgetRef ref,
    SupplementModel supplement,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(supplementCheckInControllerProvider.notifier)
          .checkIn(supplement.id);
      messenger.showSnackBar(
        SnackBar(content: Text('Check-in registrado: ${supplement.name}')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Falha no check-in: $error')),
      );
    }
  }
}

class _SupplementTile extends StatelessWidget {
  const _SupplementTile({
    required this.supplement,
    required this.isCheckingIn,
    required this.onCheckIn,
  });

  final SupplementModel supplement;
  final bool isCheckingIn;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    final macros = supplement.macronutrientsPerServing;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              child: const Icon(Icons.fitness_center),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplement.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${supplement.type} • ${macros.calories.toStringAsFixed(0)} kcal por porção',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Impacta macros: ${supplement.impactsMacronutrients ? 'sim' : 'não'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Check-in',
              onPressed: isCheckingIn ? null : onCheckIn,
              icon: isCheckingIn
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySupplements extends StatelessWidget {
  const _EmptySupplements();

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
                Icon(Icons.fitness_center),
                SizedBox(height: 12),
                Text('Nenhum suplemento encontrado.'),
                SizedBox(height: 4),
                Text(
                  'Verifique se o backend local está rodando com seed aplicado.',
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
