import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tarea_5/data/local/favorites_db.dart';
import 'package:tarea_5/data/models/user.dart';

import 'fixtures.dart';

User _user(int id, String name) => User.fromJson({
  ...jsonDecode(userJson) as Map<String, dynamic>,
  'id': id,
  'name': name,
});

void main() {
  sqfliteFfiInit();
  late FavoritesDb db;

  setUp(() async {
    db = await FavoritesDb.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
  });

  tearDown(() => db.close());

  test('a saved user reads back identical', () async {
    final user = _user(1, 'Leanne Graham');
    await db.insert(user, DateTime(2026, 10, 25));

    expect(await db.getAll(), [user]);
    expect(await db.isFavorite(1), isTrue);
    expect(await db.ids(), {1});
  });

  test('getAll returns the most recently saved first', () async {
    await db.insert(_user(1, 'A'), DateTime(2026, 1, 1));
    await db.insert(_user(2, 'B'), DateTime(2026, 3, 1));
    await db.insert(_user(3, 'C'), DateTime(2026, 2, 1));

    expect((await db.getAll()).map((u) => u.id), [2, 3, 1]);
  });

  test('inserting the same id twice keeps one row', () async {
    await db.insert(_user(1, 'Old'), DateTime(2026, 1, 1));
    await db.insert(_user(1, 'New'), DateTime(2026, 1, 2));

    final all = await db.getAll();
    expect(all, hasLength(1));
    expect(all.single.name, 'New');
  });

  test('delete removes the favorite', () async {
    await db.insert(_user(1, 'A'), DateTime(2026, 1, 1));
    await db.delete(1);

    expect(await db.getAll(), isEmpty);
    expect(await db.isFavorite(1), isFalse);
  });

  test('a corrupt row is skipped instead of failing the list', () async {
    await db.insert(_user(1, 'A'), DateTime(2026, 1, 1));
    final raw = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    // sqflite returns the already-open instance for the same path, so this
    // is the database the FavoritesDb opened.
    await raw.insert('favorites', {
      'id': 2,
      'json': '{"id": "dos"}',
      'saved_at': 0,
    });

    expect((await db.getAll()).map((u) => u.id), [1]);
    expect(await db.ids(), {1});
  });
}
