import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tarea_5/data/models/post.dart';
import 'package:tarea_5/data/models/user.dart';
import 'package:tarea_5/data/user_repository.dart';

User user(int id, [String name = 'Usuario']) => User(
  id: id,
  name: '$name $id',
  username: 'u$id',
  email: 'u$id@example.com',
  phone: '',
  website: '',
  companyName: 'Empresa $id',
  city: '',
);

Post post(int id, int userId) =>
    Post(id: id, userId: userId, title: 'Título $id', body: 'Cuerpo $id');

/// Repositorio en memoria. Cada respuesta se controla con un `Completer` o
/// con un valor/error fijo.
class FakeRepository implements UserRepository {
  /// Respuesta de [fetchUsers]: una lista, o un error a lanzar.
  Object usersResult = <User>[];
  Object postsResult = <Post>[];
  Object? favoritesError;
  Object? toggleError;

  /// La llamada N a [fetchUsers] espera a `usersGates[N]` si existe, para
  /// controlar en qué orden llegan las respuestas.
  final usersGates = <Completer<void>>[];

  final saved = <int, User>{};
  int fetchUsersCalls = 0;
  int fetchPostsCalls = 0;

  @override
  final favoriteIds = ValueNotifier<Set<int>>(const {});

  @override
  Future<void> init() async => favoriteIds.value = saved.keys.toSet();

  @override
  Future<List<User>> fetchUsers() async {
    final call = fetchUsersCalls++;
    final result = usersResult;
    if (call < usersGates.length) await usersGates[call].future;
    if (result is List<User>) return result;
    throw result;
  }

  @override
  Future<List<Post>> fetchPosts(int userId) async {
    fetchPostsCalls++;
    final result = postsResult;
    if (result is List<Post>) return result;
    throw result;
  }

  @override
  Future<List<User>> favorites() async {
    if (favoritesError case final error?) throw error;
    return saved.values.toList();
  }

  @override
  Future<bool> toggleFavorite(User user) async {
    if (toggleError case final error?) throw error;
    final nowFavorite = saved.remove(user.id) == null;
    if (nowFavorite) saved[user.id] = user;
    favoriteIds.value = saved.keys.toSet();
    return nowFavorite;
  }

  @override
  void dispose() => favoriteIds.dispose();
}
