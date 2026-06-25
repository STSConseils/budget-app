import 'package:pocketbase/pocketbase.dart';

class UserBrief {
  const UserBrief({
    required this.id,
    this.nom,
    this.email,
  });

  final String id;
  final String? nom;
  final String? email;

  String get displayName {
    if (nom != null && nom!.isNotEmpty) return nom!;
    if (email != null && email!.isNotEmpty) return email!.split('@').first;
    return id;
  }

  factory UserBrief.fromRecord(RecordModel r) {
    final rawNom = r.get<String>('nom', '');
    final rawEmail = r.get<String>('email', '');
    return UserBrief(
      id: r.id,
      nom: rawNom.isEmpty ? null : rawNom,
      email: rawEmail.isEmpty ? null : rawEmail,
    );
  }
}
