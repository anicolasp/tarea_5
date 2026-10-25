import 'package:flutter/foundation.dart';

import 'local/favorites_db.dart';
import 'models/post.dart';
import 'models/user.dart';
import 'remote/api_client.dart';

/// Única fuente de datos para los ViewModels: la red para usuarios y
/// publicaciones, SQLite para los favoritos.
///
/// Los errores de red llegan como [NoInternetException] o [ApiException];
/// los de SQLite como `DatabaseException`. Los ViewModels los convierten en
/// estados de la UI.
class UserRepository {
  UserRepository(this._api, this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final ApiClient _api;
  final FavoritesDb _db;
  final DateTime Function() _now;

  /// Ids de los favoritos; lista, detalle y favoritos lo escuchan para que
  /// la estrella esté sincronizada en todas las pantallas.
  final favoriteIds = ValueNotifier<Set<int>>(const {});

  /// Serializa las escrituras de favoritos: un doble toque en la estrella
  /// se aplica como dos cambios seguidos, no como dos decisiones con el
  /// mismo estado viejo.
  Future<void> _pending = Future.value();

  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Carga los ids guardados. Se llama una vez al arrancar la app.
  Future<void> init() => _serialized(_reloadIds);

  Future<void> _reloadIds() async {
    favoriteIds.value = await _db.ids();
  }

  Future<List<User>> fetchUsers() => _api.fetchUsers();

  Future<List<Post>> fetchPosts(int userId) => _api.fetchPosts(userId);

  /// Solo lee SQLite: funciona sin conexión.
  Future<List<User>> favorites() => _db.getAll();

  /// Agrega o quita [user] de favoritos y devuelve si quedó como favorito.
  /// SQLite decide el estado actual, así funciona aunque [init] fallara.
  Future<bool> toggleFavorite(User user) => _serialized(() async {
    final nowFavorite = !await _db.isFavorite(user.id);
    if (nowFavorite) {
      await _db.insert(user, _now());
    } else {
      await _db.delete(user.id);
    }
    await _reloadIds();
    return nowFavorite;
  });

  void dispose() => favoriteIds.dispose();
}
