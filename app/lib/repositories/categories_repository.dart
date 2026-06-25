import 'package:pocketbase/pocketbase.dart';
import 'package:budget_app/core/pb.dart';
import 'package:budget_app/models/category.dart';

class CategoriesRepository {
  Future<List<Category>> list(String householdId) async {
    final records = await pb.collection('categories').getFullList(
          filter: 'household = "$householdId"',
          sort: 'nom',
        );
    return records.map(Category.fromRecord).toList();
  }

  Future<Category> create(Category c) async {
    final record =
        await pb.collection('categories').create(body: c.toJson());
    return Category.fromRecord(record);
  }

  Future<Category> update(Category c) async {
    final record = await pb
        .collection('categories')
        .update(c.id, body: c.toJson());
    return Category.fromRecord(record);
  }

  Future<void> delete(String id) =>
      pb.collection('categories').delete(id);

  Future<UnsubscribeFunc> subscribe(
    String householdId,
    void Function() onChange,
  ) {
    return pb.collection('categories').subscribe(
          '*',
          (e) => onChange(),
          filter: 'household = "$householdId"',
        );
  }
}
