import 'package:pocketbase/pocketbase.dart';

class PersoEntry {
  const PersoEntry({
    required this.id,
    required this.ownerId,
    required this.montant,
    required this.date,
    this.note,
    this.categorieId,
  });

  final String id;
  final String ownerId;
  final double montant;
  final DateTime date;
  final String? note;
  final String? categorieId;

  factory PersoEntry.fromRecord(RecordModel r) {
    final rawNote = r.get<String>('note', '');
    final rawCat = r.get<String>('categorie', '');
    return PersoEntry(
      id: r.id,
      ownerId: r.get<String>('owner', ''),
      montant: r.getDoubleValue('montant', 0),
      date: DateTime.parse(r.get<String>('date')),
      note: rawNote.isEmpty ? null : rawNote,
      categorieId: rawCat.isEmpty ? null : rawCat,
    );
  }

  Map<String, dynamic> toJson() => {
        'owner': ownerId,
        'montant': montant,
        'date': date.toIso8601String(),
        'note': note ?? '',
        if (categorieId != null) 'categorie': categorieId,
      };
}
