import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/main.dart';

void main() {
  testWidgets('App renders placeholder screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BudgetApp()));
    await tester.pumpAndSettle();
    expect(find.text('Budget'), findsOneWidget);
  });
}
