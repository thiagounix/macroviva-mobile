import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai_analysis/presentation/meal_analysis_result_page.dart';
import '../../features/ai_analysis/presentation/meal_photo_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/foods/presentation/foods_page.dart';
import '../../features/meals/presentation/new_meal_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/supplements/presentation/supplements_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/dashboard'),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(path: '/foods', builder: (context, state) => const FoodsPage()),
      GoRoute(
        path: '/meals/new',
        builder: (context, state) => const NewMealPage(),
      ),
      GoRoute(
        path: '/meal-photo',
        builder: (context, state) => const MealPhotoPage(),
      ),
      GoRoute(
        path: '/meal-analysis-result',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is MealAnalysisResultArgs) {
            return MealAnalysisResultPage(args: extra);
          }

          return const MealPhotoPage();
        },
      ),
      GoRoute(
        path: '/supplements',
        builder: (context, state) => const SupplementsPage(),
      ),
    ],
  );
});
