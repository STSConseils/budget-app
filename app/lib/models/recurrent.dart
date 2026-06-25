import 'package:pocketbase/pocketbase.dart';

enum Sens {
  depense,
  revenu;

  static Sens fromString(String v) =>
      v == 'revenu' ? Sens.revenu : Sens.depense;

  String get value => name;
}

enum Frequence {
  mensuel,
  trimestriel,
  annuel;

  static Frequence fromString(String v) {
    switch (v) {
      case 'trimestriel':
        return Frequence.trimestriel;
      case 'annuel':
        return Frequence.annuel;
      default:
        return Frequence.mensuel;
    }
  }

  String get value => name;
}

class Recurrent {
  const Recurrent({
    required this.id,
    required this.household,
    required this.libelle,
    required this.montant,
    required this.sens,
    required this.frequence,
    required this.jourDuMois,
    required this.categorieId,
    required this.actif,
    this.personneId,
  });

  final String id;
  final String household;
  final String libelle;
  final double montant;
  final Sens sens;
  final Frequence frequence;
  final int jourDuMois;
  final String categorieId;
  final bool actif;
  final String? personneId;

  factory Recurrent.fromRecord(RecordModel r) {
    final rawPersonne = r.get<String>('personne', '');
    return Recurrent(
      id: r.id,
      household: r.get<String>('household', ''),
      libelle: r.get<String>('libelle', ''),
      montant: r.getDoubleValue('montant', 0),
      sens: Sens.fromString(r.get<String>('sens', 'depense')),
      frequence:
          Frequence.fromString(r.get<String>('frequence', 'mensuel')),
      jourDuMois: r.getIntValue('jour_du_mois', 1),
      categorieId: r.get<String>('categorie', ''),
      actif: r.getBoolValue('actif', true),
      personneId: rawPersonne.isEmpty ? null : rawPersonne,
    );
  }

  Map<String, dynamic> toJson() => {
        'household': household,
        'libelle': libelle,
        'montant': montant,
        'sens': sens.value,
        'frequence': frequence.value,
        'jour_du_mois': jourDuMois,
        'categorie': categorieId,
        'actif': actif,
        if (personneId != null) 'personne': personneId,
      };
}
