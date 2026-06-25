import 'package:pocketbase/pocketbase.dart';

enum CategoryType {
  depense,
  revenu;

  static CategoryType fromString(String v) =>
      v == 'revenu' ? CategoryType.revenu : CategoryType.depense;

  String get value => name;
}

class Category {
  const Category({
    required this.id,
    required this.household,
    required this.nom,
    required this.type,
    this.couleur,
    this.icone,
    this.budgetMensuel,
  });

  final String id;
  final String household;
  final String nom;
  final CategoryType type;
  final String? couleur;
  final String? icone;
  final double? budgetMensuel;

  factory Category.fromRecord(RecordModel r) {
    final rawBudget = r.data['budget_mensuel'];
    final rawCouleur = r.get<String>('couleur', '');
    final rawIcone = r.get<String>('icone', '');
    return Category(
      id: r.id,
      household: r.get<String>('household', ''),
      nom: r.get<String>('nom', ''),
      type: CategoryType.fromString(r.get<String>('type', 'depense')),
      couleur: rawCouleur.isEmpty ? null : rawCouleur,
      icone: rawIcone.isEmpty ? null : rawIcone,
      budgetMensuel:
          rawBudget == null ? null : (rawBudget as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'household': household,
        'nom': nom,
        'type': type.value,
        'couleur': couleur ?? '',
        'icone': icone ?? '',
        if (budgetMensuel != null) 'budget_mensuel': budgetMensuel,
      };
}
