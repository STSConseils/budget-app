import 'package:pocketbase/pocketbase.dart';
import 'package:budget_app/core/pb.dart';
import 'package:budget_app/models/perso_entry.dart';

class PersoLedgerRepository {
  // Server-side access rules already scope to the authenticated user.
  Future<List<PersoEntry>> listForUser(String userId) async {
    final records = await pb.collection('perso_ledger').getFullList(
          filter: 'owner = "$userId"',
          sort: '-date',
        );
    return records.map(PersoEntry.fromRecord).toList();
  }

  Future<PersoEntry> create(PersoEntry e) async {
    final record =
        await pb.collection('perso_ledger').create(body: e.toJson());
    return PersoEntry.fromRecord(record);
  }

  Future<PersoEntry> update(PersoEntry e) async {
    final record = await pb
        .collection('perso_ledger')
        .update(e.id, body: e.toJson());
    return PersoEntry.fromRecord(record);
  }

  Future<void> delete(String id) =>
      pb.collection('perso_ledger').delete(id);

  Future<UnsubscribeFunc> subscribe(void Function() onChange) {
    return pb
        .collection('perso_ledger')
        .subscribe('*', (e) => onChange());
  }
}
