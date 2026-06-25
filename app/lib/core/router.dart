import 'dart:async' show StreamSubscription;
import 'package:flutter/material.dart' show ChangeNotifier;
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart' show AuthStoreEvent;
import 'package:budget_app/core/pb.dart';
import 'package:budget_app/features/auth/login_screen.dart';
import 'package:budget_app/features/dashboard/dashboard_screen.dart';

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
  ],
);
