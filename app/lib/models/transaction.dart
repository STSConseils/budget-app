import 'package:pocketbase/pocketbase.dart';

// Named TransactionModel to avoid conflict with dart:async Transaction.
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.household,
    required this.montant,
    required this.date,
    required this.categorieId,
    required this.auteurId,
    this.note,
    this.recurrentSourceId,
  });

  final String id;
  final String household;
  final double montant;
  final DateTime date;
  final String categorieId;
  final String auteurId;
  final String? note;
  final String? recurrentSourceId;

  factory TransactionModel.fromRecord(RecordModel r) {
    final rawNote = r.get<String>('note', '');
    final rawSource = r.get<String>('recurrent_source', '');
    return TransactionModel(
      id: r.id,
      household: r.get<String>('household', ''),
      montant: r.getDoubleValue('montant', 0),
      date: DateTime.parse(r.get<String>('date')),
      categorieId: r.get<String>('categorie', ''),
      auteurId: r.get<String>('auteur', ''),
      note: rawNote.isEmpty ? null : rawNote,
      recurrentSourceId: rawSource.isEmpty ? null : rawSource,
    );
  }

  Map<String, dynamic> toJson() => {
        'household': household,
        'montant': montant,
        'date': date.toIso8601String(),
        'categorie': categorieId,
        'auteur': auteurId,
        'note': note ?? '',
        if (recurrentSourceId != null) 'recurrent_source': recurrentSourceId,
      };
}
