import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tarea_5/data/remote/api_client.dart';

import 'fixtures.dart';

ApiClient _clientReturning(
  Future<http.Response> Function(http.Request) handler, {
  Duration timeout = const Duration(seconds: 10),
}) => ApiClient(client: MockClient(handler), timeout: timeout);

void main() {
  test('fetchUsers parses the list from /users', () async {
    late Uri requested;
    final api = _clientReturning((request) async {
      requested = request.url;
      return http.Response('[$userJson]', 200);
    });

    final users = await api.fetchUsers();

    expect(requested.toString(), 'https://jsonplaceholder.typicode.com/users');
    expect(users.single.name, 'Leanne Graham');
    expect(users.single.companyName, 'Romaguera-Crona');
  });

  test('fetchPosts(1) requests /posts?userId=1 and returns 10 posts', () async {
    late Uri requested;
    final body = '[${List.filled(10, postJson).join(',')}]';
    final api = _clientReturning((request) async {
      requested = request.url;
      return http.Response(body, 200);
    });

    final posts = await api.fetchPosts(1);

    expect(requested.path, '/posts');
    expect(requested.queryParameters, {'userId': '1'});
    expect(posts, hasLength(10));
    expect(posts.every((p) => p.userId == 1), isTrue);
  });

  test('SocketException becomes NoInternetException', () {
    final api = _clientReturning(
      (_) => throw const SocketException('Failed host lookup'),
    );

    expect(api.fetchUsers(), throwsA(isA<NoInternetException>()));
  });

  test('ClientException becomes NoInternetException', () {
    final api = _clientReturning(
      (_) => throw http.ClientException('Connection closed'),
    );

    expect(api.fetchUsers(), throwsA(isA<NoInternetException>()));
  });

  test('non-200 status becomes ApiException', () {
    final api = _clientReturning((_) async => http.Response('oops', 500));

    expect(api.fetchUsers(), throwsA(isA<ApiException>()));
  });

  test('invalid JSON becomes ApiException', () {
    final api = _clientReturning((_) async => http.Response('<html>', 200));

    expect(api.fetchUsers(), throwsA(isA<ApiException>()));
  });

  test('unexpected JSON shape becomes ApiException', () {
    final api = _clientReturning((_) async => http.Response('{"id": 1}', 200));

    expect(api.fetchUsers(), throwsA(isA<ApiException>()));
  });

  test('list with a malformed element becomes ApiException', () {
    final api = _clientReturning(
      (_) async => http.Response('[{"id": "1", "name": "X"}]', 200),
    );

    expect(api.fetchUsers(), throwsA(isA<ApiException>()));
  });

  test('TLS handshake failure becomes NoInternetException', () {
    final api = _clientReturning(
      (_) => throw const HandshakeException('Bad certificate'),
    );

    expect(api.fetchUsers(), throwsA(isA<NoInternetException>()));
  });

  test('any other failure becomes ApiException', () {
    final api = _clientReturning((_) => throw StateError('boom'));

    expect(api.fetchUsers(), throwsA(isA<ApiException>()));
  });

  test('close does not close an injected client', () async {
    final inner = MockClient((_) async => http.Response('[]', 200));
    ApiClient(client: inner).close();

    expect((await inner.get(Uri.parse('https://x.test'))).statusCode, 200);
  });

  test('timeout becomes ApiException', () {
    final api = _clientReturning(
      (_) => Completer<http.Response>().future,
      timeout: const Duration(milliseconds: 10),
    );

    expect(api.fetchUsers(), throwsA(isA<ApiException>()));
  });
}
