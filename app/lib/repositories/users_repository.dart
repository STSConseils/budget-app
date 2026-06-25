import 'package:budget_app/core/pb.dart';
import 'package:budget_app/models/user_brief.dart';

class UsersRepository {
  Future<UserBrief> getById(String id) async {
    final record = await pb.collection('users').getOne(id);
    return UserBrief.fromRecord(record);
  }

  Future<List<UserBrief>> listByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final filter = ids.map((id) => 'id = "$id"').join(' || ');
    final records =
        await pb.collection('users').getFullList(filter: filter);
    return records.map(UserBrief.fromRecord).toList();
  }
}
