import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budget_app/repositories/providers.dart';

// Re-export du stream existant sous le nom du module.
final persoEntriesStreamProvider = persoLedgerStreamProvider;

// ─── Totaux calculés ──────────────────────────────────────────────────────────

final persoTotalMoisProvider = Provider<double>((ref) {
  final entries = ref.watch(persoLedgerStreamProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return entries
      .where((e) => e.date.year == now.year && e.date.month == now.month)
      .fold(0.0, (sum, e) => sum + e.montant);
});

final persoTotalAnneeProvider = Provider<double>((ref) {
  final entries = ref.watch(persoLedgerStreamProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return entries
      .where((e) => e.date.year == now.year)
      .fold(0.0, (sum, e) => sum + e.montant);
});
