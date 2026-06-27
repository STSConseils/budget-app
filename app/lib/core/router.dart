import 'dart:async' show StreamSubscription;
import 'package:flutter/material.dart' show ChangeNotifier;
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart' show AuthStoreEvent;
import 'package:budget_app/core/pb.dart';
import 'package:budget_app/features/auth/login_screen.dart';
import 'package:budget_app/features/categories/categories_list_screen.dart';
import 'package:budget_app/features/categories/category_form_screen.dart';
import 'package:budget_app/features/dashboard/dashboard_screen.dart';
import 'package:budget_app/features/aide/aide_screen.dart';
import 'package:budget_app/features/epargne/epargne_screen.dart';
import 'package:budget_app/features/perso/perso_screen.dart';
import 'package:budget_app/features/recurrents/recurrents_list_screen.dart';
import 'package:budget_app/features/recurrents/recurrent_form_screen.dart';
import 'package:budget_app/features/transactions/category_detail_screen.dart';
import 'package:budget_app/features/transactions/transaction_form_screen.dart';

bool _isLoggedIn() => pb.authStore.isValid;

class _AuthListenable extends ChangeNotifier {
  late final StreamSubscription<AuthStoreEvent> _sub;

  _AuthListenable() {
    _sub = pb.authStore.onChange.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final appRouter = GoRouter(
  refreshListenable: _AuthListenable(),
  redirect: (context, state) {
    final loggedIn = _isLoggedIn();
    final isLoginRoute = state.matchedLocation == '/login';
    if (!loggedIn && !isLoginRoute) return '/login';
    if (loggedIn && isLoginRoute) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/transactions/new',
      builder: (context, state) => const TransactionFormScreen(),
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoriesListScreen(),
    ),
    GoRoute(
      path: '/categories/new',
      builder: (context, state) => const CategoryFormScreen(),
    ),
    GoRoute(
      path: '/categories/:id/edit',
      builder: (context, state) => CategoryFormScreen(
        categoryId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/categories/:id',
      builder: (context, state) => CategoryDetailScreen(
        categoryId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/aide',
      builder: (context, state) => const AideScreen(),
    ),
    GoRoute(
      path: '/epargne',
      builder: (context, state) => const EpargneScreen(),
    ),
    GoRoute(
      path: '/perso',
      builder: (context, state) => const PersoScreen(),
    ),
    GoRoute(
      path: '/recurrents',
      builder: (context, state) => const RecurrentsListScreen(),
    ),
    GoRoute(
      path: '/recurrents/new',
      builder: (context, state) => const RecurrentFormScreen(),
    ),
    GoRoute(
      path: '/recurrents/:id/edit',
      builder: (context, state) => RecurrentFormScreen(
        recurrentId: state.pathParameters['id']!,
      ),
    ),
  ],
);
