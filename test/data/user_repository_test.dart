import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tarea_5/data/local/favorites_db.dart';
import 'package:tarea_5/data/models/user.dart';
import 'package:tarea_5/data/remote/api_client.dart';
import 'package:tarea_5/data/user_repository.dart';

import 'fixtures.dart';

final _user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);

/// ApiClient sin conexión: cualquier petición falla como en modo avión.
ApiClient _offlineApi() => ApiClient(
  client: MockClient((_) => throw const SocketException('offline')),
);

void main() {
  sqfliteFfiInit();
  late FavoritesDb db;
  late UserRepository repo;

  setUp(() async {
    db = await FavoritesDb.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    repo = UserRepository(_offlineApi(), db);
    await repo.init();
  });

  tearDown(() async {
    repo.dispose();
    await db.close();
  });

  test('toggleFavorite adds, then removes the user', () async {
    expect(await repo.toggleFavorite(_user), isTrue);
    expect(repo.favoriteIds.value, {1});
    expect(await repo.favorites(), [_user]);

    expect(await repo.toggleFavorite(_user), isFalse);
    expect(repo.favoriteIds.value, isEmpty);
    expect(await repo.favorites(), isEmpty);
  });

  test('favoriteIds notifies listeners on change', () async {
    var notified = 0;
    repo.favoriteIds.addListener(() => notified++);

    await repo.toggleFavorite(_user);
    await repo.toggleFavorite(_user);

    expect(notified, 2);
  });

  test('favorites work with no internet', () async {
    await repo.toggleFavorite(_user);

    await expectLater(repo.fetchUsers(), throwsA(isA<NoInternetException>()));
    expect(await repo.favorites(), [_user]);
  });

  test('a double tap applies two toggles in order', () async {
    final results = await Future.wait([
      repo.toggleFavorite(_user),
      repo.toggleFavorite(_user),
    ]);

    expect(results, [true, false]);
    expect(repo.favoriteIds.value, isEmpty);
    expect(await repo.favorites(), isEmpty);
  });

  test('toggle removes a saved favorite even without init', () async {
    await db.insert(_user, DateTime(2026, 10, 25));
    final fresh = UserRepository(_offlineApi(), db);

    expect(await fresh.toggleFavorite(_user), isFalse);
    expect(await fresh.favorites(), isEmpty);
    fresh.dispose();
  });

  test('init loads favorites saved in a previous session', () async {
    await db.insert(_user, DateTime(2026, 10, 25));
    final fresh = UserRepository(_offlineApi(), db);

    await fresh.init();

    expect(fresh.favoriteIds.value, {1});
    fresh.dispose();
  });
}
