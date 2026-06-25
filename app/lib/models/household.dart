import 'package:pocketbase/pocketbase.dart';

class Household {
  const Household({
    required this.id,
    required this.nom,
    required this.memberIds,
  });

  final String id;
  final String nom;
  final List<String> memberIds;

  factory Household.fromRecord(RecordModel r) => Household(
        id: r.id,
        nom: r.get<String>('nom', ''),
        memberIds: r.getListValue<String>('members', []),
      );
}
