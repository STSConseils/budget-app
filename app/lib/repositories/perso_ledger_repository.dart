import 'package:pocketbase/pocketbase.dart';
import 'package:budget_app/core/pb.dart';
import 'package:budget_app/models/perso_entry.dart';

String _dateFmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class PersoLedgerRepository {
  // Server-side access rules already scope to the authenticated user.
  Future<List<PersoEntry>> listForUser(String userId) async {
    final records = await pb.collection('perso_ledger').getFullList(
          filter: 'owner = "$userId"',
          sort: '-date',
        );
    return records.map(PersoEntry.fromRecord).toList();
  }

  Future<List<PersoEntry>> listForUserMonth(
    String userId,
    DateTime month,
  ) async {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1);
    final records = await pb.collection('perso_ledger').getFullList(
          filter: 'owner = "$userId"'
              ' && date >= "${_dateFmt(from)}"'
              ' && date < "${_dateFmt(to)}"',
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

  Future<int> countByCategory(String catId) async {
    final result = await pb.collection('perso_ledger').getList(
      page: 1,
      perPage: 1,
      filter: 'categorie = "$catId"',
    );
    return result.totalItems;
  }

  Future<void> delete(String id) =>
      pb.collection('perso_ledger').delete(id);

  Future<UnsubscribeFunc> subscribe(
    String userId,
    void Function() onChange,
  ) {
    return pb.collection('perso_ledger').subscribe(
          '*',
          (e) => onChange(),
          filter: 'owner = "$userId"',
        );
  }
}
