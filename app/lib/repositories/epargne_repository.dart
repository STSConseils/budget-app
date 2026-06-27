import 'package:pocketbase/pocketbase.dart';
import 'package:budget_app/core/pb.dart';
import 'package:budget_app/models/epargne.dart';

class EpargneRepository {
  Future<Epargne?> latest(String householdId) async {
    final result = await pb.collection('epargne').getList(
          page: 1,
          perPage: 1,
          skipTotal: true,
          filter: 'household = "$householdId"',
          sort: '-date',
        );
    if (result.items.isEmpty) return null;
    return Epargne.fromRecord(result.items.first);
  }

  Future<List<Epargne>> history(
    String householdId, {
    int limit = 36,
  }) async {
    final result = await pb.collection('epargne').getList(
          page: 1,
          perPage: limit,
          skipTotal: true,
          filter: 'household = "$householdId"',
          sort: 'date', // ASC pour la courbe
        );
    return result.items.map(Epargne.fromRecord).toList();
  }

  Future<Epargne> create(Epargne e) async {
    final record =
        await pb.collection('epargne').create(body: e.toJson());
    return Epargne.fromRecord(record);
  }

  Future<Epargne> update(Epargne e) async {
    final record =
        await pb.collection('epargne').update(e.id, body: e.toJson());
    return Epargne.fromRecord(record);
  }

  Future<void> delete(String id) =>
      pb.collection('epargne').delete(id);

  Future<UnsubscribeFunc> subscribe(
    String householdId,
    void Function() onChange,
  ) {
    return pb.collection('epargne').subscribe(
          '*',
          (e) => onChange(),
          filter: 'household = "$householdId"',
        );
  }
}
