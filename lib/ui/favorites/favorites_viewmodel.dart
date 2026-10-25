import 'package:flutter/foundation.dart';

import '../../data/models/user.dart';
import '../../data/user_repository.dart';
import '../ui_state.dart';

/// ViewModel de Favoritos. Solo lee SQLite, así que nunca queda en
/// [Offline]: funciona en modo avión.
class FavoritesViewModel extends ChangeNotifier with SafeNotifier {
  FavoritesViewModel(this._repo) {
    // Una estrella cambiada en otra pantalla recarga esta lista.
    _repo.favoriteIds.addListener(load);
  }

  final UserRepository _repo;

  UiState<List<User>> _state = const Loading();
  UiState<List<User>> get state => _state;

  ValueListenable<Set<int>> get favoriteIds => _repo.favoriteIds;

  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    // Solo se muestra el spinner la primera vez; después se reemplaza la
    // lista sin parpadeo.
    if (_state is! Success) {
      _state = const Loading();
      notifyListeners();
    }

    final next = await fetchState(_repo.favorites);
    if (generation != _generation) return;
    // Si falla una recarga en segundo plano se conserva la lista visible.
    if (next is Failure && _state is Success) return;
    _state = next;
    notifyListeners();
  }

  /// Devuelve si quedó como favorito, o `null` si no se pudo guardar.
  Future<bool?> toggleFavorite(User user) =>
      safeToggle(() => _repo.toggleFavorite(user));

  @override
  void dispose() {
    _repo.favoriteIds.removeListener(load);
    super.dispose();
  }
}
