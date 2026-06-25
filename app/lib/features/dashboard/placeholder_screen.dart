import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budget_app/core/theme.dart';
import 'package:budget_app/repositories/providers.dart';

class PlaceholderScreen extends ConsumerWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            color: AppColors.muted,
            tooltip: 'Déconnexion',
            onPressed: () {
              ref.read(authRepoProvider).logout();
              ref.invalidate(currentUserProvider);
              ref.invalidate(currentHouseholdProvider);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Budget', style: AppTextStyles.hero),
            const SizedBox(height: 8),
            Text('FLOOZEE.CH', style: AppTextStyles.sectionTitle),
          ],
        ),
      ),
    );
  }
}
