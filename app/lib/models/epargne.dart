import 'package:pocketbase/pocketbase.dart';

class Epargne {
  const Epargne({
    required this.id,
    required this.household,
    required this.date,
    required this.libelle,
    required this.solde,
  });

  final String id;
  final String household;
  final DateTime date;
  final String libelle;
  final double solde;

  factory Epargne.fromRecord(RecordModel r) => Epargne(
        id: r.id,
        household: r.get<String>('household', ''),
        date: DateTime.parse(r.get<String>('date')),
        libelle: r.get<String>('libelle', ''),
        solde: r.getDoubleValue('solde', 0),
      );

  Map<String, dynamic> toJson() => {
        'household': household,
        'date': date.toIso8601String(),
        'libelle': libelle,
        'solde': solde,
      };
}
