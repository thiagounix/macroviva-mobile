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
              return const Center(child: Text('Nenhum suplemento encontrado.'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(supplementsProvider);
                await ref.read(supplementsProvider.future);
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  return _SupplementTile(
                    supplement: items[index],
                    isCheckingIn: checkInState.isLoading,
                    onCheckIn: () => _checkIn(context, ref, items[index]),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemCount: items.length,
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
      child: ListTile(
        leading: const Icon(Icons.fitness_center),
        title: Text(supplement.name),
        subtitle: Text(
          '${supplement.type} - ${macros.calories.toStringAsFixed(0)} kcal por porcao\n'
          'Impacta macros: ${supplement.impactsMacronutrients ? 'sim' : 'nao'}',
        ),
        trailing: IconButton(
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
      ),
    );
  }
}
