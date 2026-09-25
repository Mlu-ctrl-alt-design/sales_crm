import 'dart:convert';

import 'package:daystar_sales/auth/auth_repository.dart';
import 'package:daystar_sales/auth/key_value_store.dart';
import 'package:daystar_sales/auth/mobile_control_auth.dart';
import 'package:daystar_sales/auth/token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const site = 'https://crm-staging.thedaystar.co.za';

class MemoryStore implements KeyValueStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// Shaped like mobile_control's build_auth_response (tokens at top level).
Map<String, Object?> authBody({
  String access = 'gAAAAaccess1',
  String refresh = 'refresh1',
}) => {
  'message': 'Logged In',
  'user': 'mlu@thedaystar.co.za',
  'full_name': 'Mlu',
  'language': 'en',
  'access_token': access,
  'refresh_token': refresh,
  'offline_enabled': false,
  'mobile_form_names': [],
  'roles': ['Mobile User'],
  'permissions': [],
};

http.Response json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

class Clock {
  DateTime value = DateTime.utc(2026, 9, 25, 20);
  DateTime call() => value;
}

void main() {
  late MemoryStore store;
  late Clock clock;
  late List<http.Request> requests;

  MobileControlAuthRepository repo(
    Future<http.Response> Function(http.Request) handler,
  ) {
    return MobileControlAuthRepository(
      siteUrl: site,
      tokens: TokenStore(store),
      now: clock.call,
      client: MockClient((request) {
        requests.add(request);
        return handler(request);
      }),
    );
  }

  setUp(() {
    store = MemoryStore();
    clock = Clock();
    requests = [];
  });

  test(
    'login posts username, password and device id, and stores tokens',
    () async {
      final auth = repo((_) async => json(authBody(), 200));

      final session = await auth.login(
        username: 'mlu@thedaystar.co.za',
        password: 'pw',
      );

      expect(session.user, 'mlu@thedaystar.co.za');
      expect(session.fullName, 'Mlu');
      final request = requests.single;
      expect(request.url.toString(), '$site/api/method/mobile_auth.login');
      expect(request.method, 'POST');
      final sent = jsonDecode(request.body) as Map<String, dynamic>;
      expect(sent['username'], 'mlu@thedaystar.co.za');
      expect(sent['password'], 'pw');
      expect(sent['device_id'], isA<String>());
      expect(await auth.accessToken(), 'gAAAAaccess1');
      expect(await auth.restore(), isA<Session>());
    },
  );

  test('the device id is stable across sign-ins', () async {
    final auth = repo((_) async => json(authBody(), 200));
    await auth.login(username: 'a', password: 'b');
    await auth.login(username: 'a', password: 'b');
    final ids = requests
        .map((r) => (jsonDecode(r.body) as Map)['device_id'])
        .toSet();
    expect(ids, hasLength(1));
  });

  test('wrong password: plain message, nothing stored', () async {
    // Exactly what crm-staging returned for bad credentials on 2026-09-25.
    final auth = repo(
      (_) async => json({
        'message': 'Invalid login credentials',
        'exc_type': 'ValidationError',
        '_server_messages': '["{\\"message\\":\\"Unable to login\\"}"]',
      }, 417),
    );

    await expectLater(
      auth.login(username: 'x', password: 'y'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          "That email and password don't match.",
        ),
      ),
    );
    expect(await auth.restore(), isNull);
  });

  test('user without the Mobile User role is told what to ask for', () async {
    final auth = repo(
      (_) async => json({
        'exc_type': 'ValidationError',
        '_server_messages':
            '["{\\"message\\":\\"Not allowed to use mobile app\\"}"]',
      }, 417),
    );

    await expectLater(
      auth.login(username: 'x', password: 'y'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('Mobile User role'),
        ),
      ),
    );
  });

  test('rate limited', () async {
    final auth = repo(
      (_) async => json({'exc_type': 'TooManyRequestsError'}, 429),
    );
    await expectLater(
      auth.login(username: 'x', password: 'y'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('Too many'),
        ),
      ),
    );
  });

  test(
    'refreshes a token older than 23 hours and keeps the new pair',
    () async {
      var calls = 0;
      final auth = repo((request) async {
        calls++;
        if (request.url.path.endsWith('mobile_auth.login')) {
          return json(authBody(), 200);
        }
        expect(request.url.path, endsWith('mobile_auth.refresh_token'));
        expect((jsonDecode(request.body) as Map)['refresh_token'], 'refresh1');
        return json(authBody(access: 'gAAAAaccess2', refresh: 'refresh2'), 200);
      });
      await auth.login(username: 'a', password: 'b');

      clock.value = clock.value.add(const Duration(hours: 22));
      expect(await auth.accessToken(), 'gAAAAaccess1', reason: 'still fresh');
      expect(calls, 1);

      clock.value = clock.value.add(const Duration(hours: 1));
      expect(await auth.accessToken(), 'gAAAAaccess2');
      expect((await TokenStore(store).load())!.refreshToken, 'refresh2');
    },
  );

  test(
    'parallel callers share one refresh (old refresh token is revoked)',
    () async {
      final auth = repo((request) async {
        if (request.url.path.endsWith('mobile_auth.login')) {
          return json(authBody(), 200);
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return json(authBody(access: 'gAAAAaccess2', refresh: 'refresh2'), 200);
      });
      await auth.login(username: 'a', password: 'b');
      clock.value = clock.value.add(const Duration(days: 1));

      final tokens = await Future.wait([
        auth.accessToken(),
        auth.accessToken(),
        auth.restore(),
      ]);

      expect(
        requests.where((r) => r.url.path.endsWith('refresh_token')),
        hasLength(1),
      );
      expect(tokens[0], 'gAAAAaccess2');
    },
  );

  test('a revoked refresh token signs the user out', () async {
    final auth = repo((request) async {
      if (request.url.path.endsWith('mobile_auth.login')) {
        return json(authBody(), 200);
      }
      return json({'exc_type': 'AuthenticationError'}, 401);
    });
    await auth.login(username: 'a', password: 'b');
    clock.value = clock.value.add(const Duration(days: 2));

    expect(await auth.restore(), isNull);
    expect(await TokenStore(store).load(), isNull);
  });

  test('offline at open keeps the session', () async {
    var online = true;
    final auth = repo((request) async {
      if (!online) {
        throw http.ClientException('no signal');
      }
      return json(authBody(), 200);
    });
    await auth.login(username: 'a', password: 'b');
    clock.value = clock.value.add(const Duration(days: 1));
    online = false;

    expect((await auth.restore())?.user, 'mlu@thedaystar.co.za');
    expect(await TokenStore(store).load(), isNotNull);
  });

  test(
    'logout clears the phone and tells the server with the bearer token',
    () async {
      final auth = repo((request) async => json(authBody(), 200));
      await auth.login(username: 'a', password: 'b');

      await auth.logout();

      final logout = requests.last;
      expect(logout.url.path, endsWith('mobile_auth.logout'));
      expect(logout.headers['Authorization'], 'Bearer gAAAAaccess1');
      expect(await auth.restore(), isNull);
    },
  );
}
