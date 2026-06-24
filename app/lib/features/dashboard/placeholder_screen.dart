import 'package:flutter/material.dart';
import 'package:budget_app/core/theme.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
