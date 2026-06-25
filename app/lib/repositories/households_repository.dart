import 'package:budget_app/core/pb.dart';
import 'package:budget_app/models/household.dart';

class HouseholdsRepository {
  /// Returns the first household where [userId] is a member.
  /// Returns null if none found.
  Future<Household?> current(String userId) async {
    try {
      final record = await pb
          .collection('households')
          .getFirstListItem('members ~ "$userId"');
      return Household.fromRecord(record);
    } catch (_) {
      return null;
    }
  }
}
