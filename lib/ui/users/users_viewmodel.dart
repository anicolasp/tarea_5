import 'package:flutter/foundation.dart';

import '../../data/models/user.dart';
import '../../data/user_repository.dart';
import '../ui_state.dart';

/// ViewModel de la lista de usuarios.
class UsersViewModel extends ChangeNotifier with SafeNotifier {
  UsersViewModel(this._repo);

  final UserRepository _repo;

  UiState<List<User>> _state = const Loading();
  UiState<List<User>> get state => _state;

  String? _refreshError;

  ValueListenable<Set<int>> get favoriteIds => _repo.favoriteIds;

  /// Identifica la última carga: una respuesta vieja no pisa una nueva.
  int _generation = 0;

  Future<void> load() => _fetch(showLoading: true);

  /// Recarga sin ocultar los datos que ya se ven.
  Future<void> refresh() => _fetch(showLoading: _state is! Success);

  /// Reintento silencioso al volver a la app: solo si la última carga falló,
  /// y sin pasar por [Loading] (el mensaje sigue visible hasta que llega el
  /// resultado). Devuelve si reintentó.
  bool retryIfFailed() {
    if (_state is! Offline && _state is! Failure) return false;
    _retryQuietly();
    return true;
  }

  Future<void> _retryQuietly() async {
    final generation = ++_generation;
    final next = await fetchState(_repo.fetchUsers);
    if (generation != _generation) return;
    _state = next;
    notifyListeners();
  }

  /// Motivo del último [refresh] fallido mientras había datos visibles, o
  /// `null`. Se borra al leerlo, para que la pantalla muestre el SnackBar
  /// una sola vez.
  String? takeRefreshError() {
    final error = _refreshError;
    _refreshError = null;
    return error;
  }

  Future<void> _fetch({required bool showLoading}) async {
    final generation = ++_generation;
    _refreshError = null;
    if (showLoading) {
      _state = const Loading();
      notifyListeners();
    }

    final next = await fetchState(_repo.fetchUsers);
    if (generation != _generation) return;

    switch (next) {
      case Offline() when !showLoading:
        // Falló una recarga: se conservan los datos y se avisa.
        _refreshError = offlineMessage;
      case Failure(:final message) when !showLoading:
        _refreshError = message;
      default:
        _state = next;
    }
    notifyListeners();
  }

  /// Devuelve si [user] quedó como favorito, o `null` si no se pudo guardar.
  Future<bool?> toggleFavorite(User user) =>
      safeToggle(() => _repo.toggleFavorite(user));
}
