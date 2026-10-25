import 'package:flutter/foundation.dart';

import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/user_repository.dart';
import '../ui_state.dart';

/// ViewModel del detalle: los datos del usuario llegan ya cargados (se ven
/// aunque no haya red) y las publicaciones tienen su propio estado.
class DetailViewModel extends ChangeNotifier with SafeNotifier {
  DetailViewModel(this._repo, this.user) {
    _repo.favoriteIds.addListener(notifyListeners);
  }

  final UserRepository _repo;
  final User user;

  UiState<List<Post>> _postsState = const Loading();
  UiState<List<Post>> get postsState => _postsState;

  ValueListenable<Set<int>> get favoriteIds => _repo.favoriteIds;

  bool get isFavorite => _repo.favoriteIds.value.contains(user.id);

  int _generation = 0;

  Future<void> loadPosts() async {
    final generation = ++_generation;
    _postsState = const Loading();
    notifyListeners();

    final next = await fetchState(() => _repo.fetchPosts(user.id));
    if (generation != _generation) return;
    _postsState = next;
    notifyListeners();
  }

  /// Devuelve si quedó como favorito, o `null` si no se pudo guardar.
  Future<bool?> toggleFavorite() =>
      safeToggle(() => _repo.toggleFavorite(user));

  @override
  void dispose() {
    _repo.favoriteIds.removeListener(notifyListeners);
    super.dispose();
  }
}
