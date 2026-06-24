import 'package:go_router/go_router.dart';
import 'package:budget_app/features/dashboard/placeholder_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PlaceholderScreen(),
    ),
  ],
);
