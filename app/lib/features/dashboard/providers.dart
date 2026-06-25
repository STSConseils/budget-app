import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budget_app/models/category.dart';
import 'package:budget_app/models/recurrent.dart';
import 'package:budget_app/repositories/providers.dart';
import 'package:budget_app/features/dashboard/fiscal_labels.dart';

class CategorieBucket {
  const CategorieBucket({required this.category, required this.realise});
  final Category category;
  final double realise;
}

class FiscaleAggregat {
  const FiscaleAggregat({required this.poste, required this.total});
  final String poste;
  final double total;
}

enum PositionStatus { positive, negative, neutral }

bool _appliqueCeMois(Recurrent r, DateTime now) => switch (r.frequence) {
      Frequence.mensuel => true,
      Frequence.trimestriel => const [1, 4, 7, 10].contains(now.month),
      Frequence.annuel => now.month == 1,
    };

final realiseDepensesProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionsStreamProvider).valueOrNull ?? [];
  final cats = ref.watch(categoriesStreamProvider).valueOrNull ?? [];
  final catMap = {for (final c in cats) c.id: c};
  return txs
      .where((t) => catMap[t.categorieId]?.type == CategoryType.depense)
      .fold(0.0, (sum, t) => sum + t.montant);
});

final realiseRevenusProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionsStreamProvider).valueOrNull ?? [];
  final cats = ref.watch(categoriesStreamProvider).valueOrNull ?? [];
  final catMap = {for (final c in cats) c.id: c};
  return txs
      .where((t) => catMap[t.categorieId]?.type == CategoryType.revenu)
      .fold(0.0, (sum, t) => sum + t.montant);
});

final prevuDepensesProvider = Provider<double>((ref) {
  final recurrents = ref.watch(recurrentsStreamProvider).valueOrNull ?? [];
  final txs = ref.watch(transactionsStreamProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final paidIds = txs
      .where((t) => t.recurrentSourceId != null)
      .map((t) => t.recurrentSourceId!)
      .toSet();
  return recurrents
      .where((r) =>
          r.sens == Sens.depense &&
          _appliqueCeMois(r, now) &&
          !paidIds.contains(r.id))
      .fold(0.0, (sum, r) => sum + r.montant);
});

final prevuRevenusProvider = Provider<double>((ref) {
  final recurrents = ref.watch(recurrentsStreamProvider).valueOrNull ?? [];
  final txs = ref.watch(transactionsStreamProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final paidIds = txs
      .where((t) => t.recurrentSourceId != null)
      .map((t) => t.recurrentSourceId!)
      .toSet();
  return recurrents
      .where((r) =>
          r.sens == Sens.revenu &&
          _appliqueCeMois(r, now) &&
          !paidIds.contains(r.id))
      .fold(0.0, (sum, r) => sum + r.montant);
});

final epargneActuelleProvider = Provider<double>((ref) {
  return ref.watch(epargneLatestProvider).valueOrNull?.solde ?? 0;
});

final positionProjeteeProvider = Provider<double>((ref) {
  final epargne = ref.watch(epargneActuelleProvider);
  final revenusRealises = ref.watch(realiseRevenusProvider);
  final revenusPrevus = ref.watch(prevuRevenusProvider);
  final depensesRealisees = ref.watch(realiseDepensesProvider);
  final depensesPrevues = ref.watch(prevuDepensesProvider);
  return epargne + revenusRealises + revenusPrevus - depensesRealisees - depensesPrevues;
});

final positionStatusProvider = Provider<PositionStatus>((ref) {
  final pos = ref.watch(positionProjeteeProvider);
  if (pos > 0) return PositionStatus.positive;
  if (pos < 0) return PositionStatus.negative;
  return PositionStatus.neutral;
});

final ventilationParCategorieProvider = Provider<List<CategorieBucket>>((ref) {
  final cats = ref.watch(categoriesStreamProvider).valueOrNull ?? [];
  final txs = ref.watch(transactionsStreamProvider).valueOrNull ?? [];

  final budgetCats = cats
      .where((c) => c.type == CategoryType.depense && c.budgetMensuel != null)
      .toList()
    ..sort((a, b) => b.budgetMensuel!.compareTo(a.budgetMensuel!));

  final spent = <String, double>{};
  for (final t in txs) {
    spent[t.categorieId] = (spent[t.categorieId] ?? 0) + t.montant;
  }

  return budgetCats
      .map((c) => CategorieBucket(category: c, realise: spent[c.id] ?? 0))
      .toList();
});

final fiscaleAggregatProvider = Provider<List<FiscaleAggregat>>((ref) {
  final txs = ref.watch(transactionsAnneeProvider).valueOrNull ?? [];
  final cats = ref.watch(categoriesStreamProvider).valueOrNull ?? [];
  final catMap = {for (final c in cats) c.id: c};

  final totals = <String, double>{};
  for (final t in txs) {
    final cat = catMap[t.categorieId];
    if (cat == null) continue;
    final poste = fiscalPosteLabel(cat.nom);
    if (poste == null) continue;
    totals[poste] = (totals[poste] ?? 0) + t.montant;
  }

  return totals.entries
      .map((e) => FiscaleAggregat(poste: e.key, total: e.value))
      .toList()
    ..sort((a, b) => b.total.compareTo(a.total));
});
