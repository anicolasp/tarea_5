import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/user.dart';

/// Favoritos guardados en SQLite (mismo enfoque offline-first de la Tarea 4).
///
/// Cada fila guarda el JSON completo del usuario para poder mostrarlo sin
/// conexión.
class FavoritesDb {
  FavoritesDb._(this._db);

  final Database _db;

  static const fileName = 'directorio.db';
  static const version = 1;
  static const _table = 'favorites';

  /// Abre (y crea si hace falta) la base. Las pruebas pasan
  /// `databaseFactoryFfi` e `inMemoryDatabasePath`.
  static Future<FavoritesDb> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await dbFactory.getDatabasesPath(), fileName);
    final db = await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: version,
        onCreate: (db, _) => db.execute(
          'CREATE TABLE $_table ('
          'id INTEGER PRIMARY KEY, '
          'json TEXT NOT NULL, '
          'saved_at INTEGER NOT NULL)',
        ),
      ),
    );
    return FavoritesDb._(db);
  }

  /// Favoritos, el más reciente primero. Una fila corrupta se ignora para
  /// que un dato malo no impida ver el resto.
  Future<List<User>> getAll() async {
    final rows = await _db.query(_table, orderBy: 'saved_at DESC');
    final users = <User>[];
    for (final row in rows) {
      try {
        users.add(
          User.fromJson(
            jsonDecode(row['json'] as String) as Map<String, dynamic>,
          ),
        );
      } catch (e) {
        debugPrint('FavoritesDb: fila ${row['id']} ignorada ($e)');
      }
    }
    return users;
  }

  /// Ids de los favoritos que [getAll] puede mostrar (sin filas corruptas),
  /// para que la estrella y la pestaña Favoritos siempre coincidan.
  Future<Set<int>> ids() async => {for (final u in await getAll()) u.id};

  Future<bool> isFavorite(int id) async {
    final rows = await _db.query(
      _table,
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isNotEmpty;
  }

  Future<void> insert(User user, DateTime savedAt) => _db.insert(_table, {
    'id': user.id,
    'json': jsonEncode(user.toJson()),
    'saved_at': savedAt.millisecondsSinceEpoch,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> delete(int id) =>
      _db.delete(_table, where: 'id = ?', whereArgs: [id]);

  Future<void> close() => _db.close();
}
