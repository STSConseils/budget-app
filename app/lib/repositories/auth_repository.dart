import 'package:budget_app/core/pb.dart';

class AuthRepository {
  Future<void> login(String email, String password) =>
      pb.collection('users').authWithPassword(email, password);

  void logout() => pb.authStore.clear();
}
