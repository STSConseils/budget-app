import 'package:pocketbase/pocketbase.dart';
import 'package:budget_app/core/pb.dart';
import 'package:budget_app/models/recurrent.dart';

class RecurrentsRepository {
  Future<List<Recurrent>> list(String householdId) async {
    final records = await pb.collection('recurrents').getFullList(
          filter: 'household = "$householdId"',
          sort: 'libelle',
        );
    return records.map(Recurrent.fromRecord).toList();
  }

  Future<List<Recurrent>> listActive(String householdId) async {
    final records = await pb.collection('recurrents').getFullList(
          filter: 'household = "$householdId" && actif = true',
          sort: 'libelle',
        );
    return records.map(Recurrent.fromRecord).toList();
  }

  Future<Recurrent> create(Recurrent r) async {
    final record =
        await pb.collection('recurrents').create(body: r.toJson());
    return Recurrent.fromRecord(record);
  }

  Future<Recurrent> update(Recurrent r) async {
    final record = await pb
        .collection('recurrents')
        .update(r.id, body: r.toJson());
    return Recurrent.fromRecord(record);
  }

  Future<int> countByCategory(String catId) async {
    final result = await pb.collection('recurrents').getList(
      page: 1,
      perPage: 1,
      filter: 'categorie = "$catId"',
    );
    return result.totalItems;
  }

  Future<void> delete(String id) =>
      pb.collection('recurrents').delete(id);

  Future<UnsubscribeFunc> subscribe(
    String householdId,
    void Function() onChange,
  ) {
    return pb.collection('recurrents').subscribe(
          '*',
          (e) => onChange(),
          filter: 'household = "$householdId"',
        );
  }
}
