import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budget_app/models/category.dart';
import 'package:budget_app/models/epargne.dart';
import 'package:budget_app/models/transaction.dart';
import 'package:budget_app/repositories/providers.dart';

class EpargneStats {
  const EpargneStats({
    this.estimee,
    this.dernierReel,
    this.dateRecalage,
    this.fluxDepuis,
    this.variationReelle,
    this.dateAvant,
  });

  final double? estimee;
  final double? dernierReel;
  final DateTime? dateRecalage;
  final double? fluxDepuis;
  final double? variationReelle;
  final DateTime? dateAvant;
}

// ─── 1) Historique ASC des snapshots ─────────────────────────────────────────

final epargneHistoryProvider =
    StreamProvider<List<Epargne>>((ref) async* {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) {
    yield [];
    return;
  }
  final repo = ref.read(epargneRepoProvider);

  yield await repo.history(household.id);

  final controller = StreamController<List<Epargne>>();
  final unsub = await repo.subscribe(household.id, () async {
    controller.add(await repo.history(household.id));
  });
  ref.onDispose(() {
    unsub();
    controller.close();
  });

  yield* controller.stream;
});

// ─── 2) Dernier snapshot ──────────────────────────────────────────────────────

final lastSnapshotProvider = Provider<Epargne?>((ref) {
  final history = ref.watch(epargneHistoryProvider).valueOrNull;
  if (history == null || history.isEmpty) return null;
  return history.last; // last dans liste ASC = le plus récent
});

// ─── 3) Transactions depuis le dernier snapshot ───────────────────────────────

final transactionsSinceSnapshotStreamProvider =
    StreamProvider<List<TransactionModel>>((ref) async* {
  final household = await ref.watch(currentHouseholdProvider.future);
  if (household == null) {
    yield [];
    return;
  }

  final historyAsync = ref.watch(epargneHistoryProvider);
  final history = historyAsync.valueOrNull;
  if (history == null || history.isEmpty) {
    yield [];
    return;
  }

  final snap = history.last;
  final repo = ref.read(transactionsRepoProvider);

  yield await repo.listSince(household.id, snap.date);

  final controller = StreamController<List<TransactionModel>>();
  final unsub = await repo.subscribe(household.id, () async {
    controller.add(await repo.listSince(household.id, snap.date));
  });
  ref.onDispose(() {
    unsub();
    controller.close();
  });

  yield* controller.stream;
});

// ─── 4) Flux net depuis le snapshot ──────────────────────────────────────────

final fluxDepuisSnapshotProvider = Provider<double>((ref) {
  final txs =
      ref.watch(transactionsSinceSnapshotStreamProvider).valueOrNull ?? [];
  final cats = ref.watch(categoriesStreamProvider).valueOrNull ?? [];
  final catMap = {for (final c in cats) c.id: c};

  return txs.fold(0.0, (sum, t) {
    final type = catMap[t.categorieId]?.type;
    if (type == CategoryType.revenu) return sum + t.montant;
    if (type == CategoryType.depense) return sum - t.montant;
    return sum;
  });
});

// ─── 5) Épargne estimée (temps réel) ─────────────────────────────────────────

final epargneEstimeeProvider = Provider<double?>((ref) {
  final snap = ref.watch(lastSnapshotProvider);
  if (snap == null) return null;
  final flux = ref.watch(fluxDepuisSnapshotProvider);
  return snap.solde + flux;
});

// ─── 6) Stats complètes ───────────────────────────────────────────────────────

final epargneStatsProvider = Provider<EpargneStats>((ref) {
  final history = ref.watch(epargneHistoryProvider).valueOrNull;
  final estimee = ref.watch(epargneEstimeeProvider);
  final flux = ref.watch(fluxDepuisSnapshotProvider);

  if (history == null || history.isEmpty) {
    return const EpargneStats();
  }

  final last = history.last;
  final beforeLast =
      history.length >= 2 ? history[history.length - 2] : null;

  return EpargneStats(
    estimee: estimee,
    dernierReel: last.solde,
    dateRecalage: last.date,
    fluxDepuis: flux,
    variationReelle:
        beforeLast != null ? last.solde - beforeLast.solde : null,
    dateAvant: beforeLast?.date,
  );
});
