import 'package:flutter/material.dart';

import '../../data/user_repository.dart';
import '../detail/user_detail_screen.dart';
import '../ui_state.dart';
import '../widgets/state_views.dart';
import '../widgets/user_tile.dart';
import 'favorites_viewmodel.dart';

/// Requisito 3: favoritos guardados en SQLite, visibles sin conexión.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.repo});

  final UserRepository repo;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final FavoritesViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = FavoritesViewModel(widget.repo);
    _vm.load();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Favoritos')),
    body: ListenableBuilder(
      listenable: _vm,
      builder: (context, _) => switch (_vm.state) {
        Loading() => const LoadingView(),
        Empty() => const EmptyView(
          message:
              'Aún no tienes favoritos. Toca ☆ en un usuario para guardarlo.',
        ),
        // Favoritos solo lee SQLite, así que no debería llegar aquí.
        Offline() => OfflineView(onRetry: _vm.load),
        Failure(:final message) => ErrorView(
          message: message,
          onRetry: _vm.load,
        ),
        Success(data: final users) => ListView.separated(
          key: const ValueKey('favorites.list'),
          itemCount: users.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final user = users[i];
            return UserTile(
              key: ValueKey('favorites.item.${user.id}'),
              user: user,
              favoriteIds: _vm.favoriteIds,
              starKey: ValueKey('favorites.favorite.${user.id}'),
              onTap: () => openUserDetail(context, widget.repo, user),
              onToggleFavorite: () =>
                  toggleWithFeedback(context, _vm.toggleFavorite(user)),
            );
          },
        ),
      },
    ),
  );
}
