import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budget_app/models/recurrent.dart';
import 'package:budget_app/repositories/providers.dart';
import 'package:budget_app/features/recurrents/recurrent_status.dart';

typedef RecurrentAvecStatut = ({Recurrent rec, RecurrentStatusInfo info});

int _statusOrder(RecurrentStatus s) => switch (s) {
      RecurrentStatus.enRetard => 0,
      RecurrentStatus.aPayer => 1,
      RecurrentStatus.paye => 2,
      RecurrentStatus.inactif => 3,
    };

final recurrentsAvecStatutProvider =
    Provider<List<RecurrentAvecStatut>>((ref) {
  final recurrents = ref.watch(recurrentsAllStreamProvider).valueOrNull ?? [];
  final txs = ref.watch(transactionsStreamProvider).valueOrNull ?? [];
  final now = DateTime.now();

  final list = recurrents.map((rec) {
    final info = computeRecurrentStatus(rec, txs, now);
    return (rec: rec, info: info);
  }).toList();

  list.sort((a, b) {
    final cmp =
        _statusOrder(a.info.status).compareTo(_statusOrder(b.info.status));
    if (cmp != 0) return cmp;
    return a.rec.libelle.compareTo(b.rec.libelle);
  });

  return list;
});
