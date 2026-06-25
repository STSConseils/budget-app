import 'package:web/web.dart' as web;
import 'package:pocketbase/pocketbase.dart';

const String _kApiUrl = 'https://api.floozee.ch';
const String _kAuthKey = 'pb_auth';

final pb = PocketBase(
  _kApiUrl,
  authStore: AsyncAuthStore(
    save: (String data) async =>
        web.window.localStorage.setItem(_kAuthKey, data),
    initial: web.window.localStorage.getItem(_kAuthKey),
    clear: () async => web.window.localStorage.removeItem(_kAuthKey),
  ),
);
