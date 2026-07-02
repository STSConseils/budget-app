import 'package:pocketbase/pocketbase.dart';
import 'package:budget_app/core/pb.dart';
import 'package:budget_app/models/transaction.dart';

String _dateFmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class TransactionsRepository {
  Future<List<TransactionModel>> listForMonth(
    String householdId,
    DateTime month,
  ) async {
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1); // exclusive upper bound
    final records = await pb.collection('transactions').getFullList(
          filter: 'household = "$householdId"'
              ' && date >= "${_dateFmt(from)}"'
              ' && date < "${_dateFmt(to)}"',
          sort: '-date',
        );
    return records.map(TransactionModel.fromRecord).toList();
  }

  Future<List<TransactionModel>> listSince(
    String householdId,
    DateTime since,
  ) async {
    final records = await pb.collection('transactions').getFullList(
          filter: 'household = "$householdId"'
              ' && date >= "${_dateFmt(since)}"',
          sort: 'date',
        );
    return records.map(TransactionModel.fromRecord).toList();
  }

  Future<List<TransactionModel>> listForYear(
    String householdId,
    int year,
  ) async {
    final from = DateTime(year, 1, 1);
    final to = DateTime(year + 1, 1, 1);
    final records = await pb.collection('transactions').getFullList(
          filter: 'household = "$householdId"'
              ' && date >= "${_dateFmt(from)}"'
              ' && date < "${_dateFmt(to)}"',
          sort: '-date',
        );
    return records.map(TransactionModel.fromRecord).toList();
  }

  Future<TransactionModel> getById(String id) async {
    final record = await pb.collection('transactions').getOne(id);
    return TransactionModel.fromRecord(record);
  }

  Future<TransactionModel> create(TransactionModel t) async {
    final record =
        await pb.collection('transactions').create(body: t.toJson());
    return TransactionModel.fromRecord(record);
  }

  Future<TransactionModel> update(TransactionModel t) async {
    final record = await pb
        .collection('transactions')
        .update(t.id, body: t.toJson());
    return TransactionModel.fromRecord(record);
  }

  Future<int> countByCategory(String catId) async {
    final result = await pb.collection('transactions').getList(
      page: 1,
      perPage: 1,
      filter: 'categorie = "$catId"',
    );
    return result.totalItems;
  }

  Future<void> delete(String id) =>
      pb.collection('transactions').delete(id);

  Future<UnsubscribeFunc> subscribe(
    String householdId,
    void Function() onChange,
  ) {
    return pb.collection('transactions').subscribe(
          '*',
          (e) => onChange(),
          filter: 'household = "$householdId"',
        );
  }
}
