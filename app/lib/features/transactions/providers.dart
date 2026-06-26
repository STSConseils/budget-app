import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budget_app/models/transaction.dart';
import 'package:budget_app/models/user_brief.dart';
import 'package:budget_app/repositories/providers.dart';

final transactionsByCategoryProvider =
    Provider.family<List<TransactionModel>, String>((ref, categoryId) {
  final txs = ref.watch(transactionsStreamProvider).valueOrNull ?? [];
  return txs
      .where((t) => t.categorieId == categoryId)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

final householdMembersProvider = FutureProvider<List<UserBrief>>((ref) async {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) return [];
  return ref.read(usersRepoProvider).listByIds(household.memberIds);
});
