import 'package:budget_app/models/recurrent.dart';
import 'package:budget_app/models/transaction.dart';

enum RecurrentStatus { inactif, paye, aPayer, enRetard }

class RecurrentStatusInfo {
  const RecurrentStatusInfo({
    required this.status,
    this.prochaineEcheance,
    this.joursRestants,
  });

  final RecurrentStatus status;
  final DateTime? prochaineEcheance;
  final int? joursRestants;
}

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

DateTime? _echeanceCeMois(Recurrent rec, DateTime now) {
  final maxDay = _daysInMonth(now.year, now.month);
  final day = rec.jourDuMois.clamp(1, maxDay);
  switch (rec.frequence) {
    case Frequence.mensuel:
      return DateTime(now.year, now.month, day);
    case Frequence.trimestriel:
      if (![1, 4, 7, 10].contains(now.month)) return null;
      return DateTime(now.year, now.month, day);
    case Frequence.annuel:
      if (now.month != 1) return null;
      return DateTime(now.year, now.month, day);
  }
}

RecurrentStatusInfo computeRecurrentStatus(
  Recurrent rec,
  List<TransactionModel> transactionsDuMois,
  DateTime now,
) {
  if (!rec.actif) {
    return const RecurrentStatusInfo(status: RecurrentStatus.inactif);
  }

  final echeance = _echeanceCeMois(rec, now);
  if (echeance == null) {
    return const RecurrentStatusInfo(status: RecurrentStatus.inactif);
  }

  final isPaid = transactionsDuMois.any((t) => t.recurrentSourceId == rec.id);
  if (isPaid) {
    return RecurrentStatusInfo(
      status: RecurrentStatus.paye,
      prochaineEcheance: echeance,
    );
  }

  final today = DateTime(now.year, now.month, now.day);
  if (echeance.isBefore(today)) {
    return RecurrentStatusInfo(
      status: RecurrentStatus.enRetard,
      prochaineEcheance: echeance,
    );
  }

  final joursRestants = echeance.difference(today).inDays;
  return RecurrentStatusInfo(
    status: RecurrentStatus.aPayer,
    prochaineEcheance: echeance,
    joursRestants: joursRestants,
  );
}
