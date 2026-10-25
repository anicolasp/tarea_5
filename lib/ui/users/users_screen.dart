import 'package:flutter/material.dart';

import '../../data/user_repository.dart';
import '../detail/user_detail_screen.dart';
import '../ui_state.dart';
import '../widgets/state_views.dart';
import '../widgets/user_tile.dart';
import 'users_viewmodel.dart';

/// Requisito 1: lista de usuarios con nombre, correo y empresa.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key, required this.repo});

  final UserRepository repo;

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late final UsersViewModel _vm;

  @override
  void initState() {
    super.initState();
    // Primera carga al crear la pantalla (≈ onCreate en Android).
    _vm = UsersViewModel(widget.repo)..addListener(_showRefreshError);
    _vm.load();
  }

  @override
  void dispose() {
    // Libera el ViewModel (≈ onDestroy / onCleared en Android).
    _vm.dispose();
    super.dispose();
  }

  void _showRefreshError() {
    final error = _vm.takeRefreshError();
    if (error == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Usuarios')),
    body: ListenableBuilder(
      listenable: _vm,
      builder: (context, _) => switch (_vm.state) {
        Loading() => const LoadingView(),
        Empty() => const EmptyView(message: 'No hay usuarios para mostrar.'),
        Offline() => OfflineView(onRetry: _vm.load),
        Failure(:final message) => ErrorView(
          message: message,
          onRetry: _vm.load,
        ),
        // Pull-to-refresh solo sobre la lista; en los demás estados se usa
        // "Reintentar" (evita dos spinners a la vez).
        Success(data: final users) => RefreshIndicator(
          onRefresh: _vm.refresh,
          child: ListView.separated(
            key: const ValueKey('users.list'),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: users.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final user = users[i];
              return UserTile(
                key: ValueKey('users.item.${user.id}'),
                user: user,
                favoriteIds: _vm.favoriteIds,
                starKey: ValueKey('users.favorite.${user.id}'),
                onTap: () => openUserDetail(context, widget.repo, user),
                onToggleFavorite: () =>
                    toggleWithFeedback(context, _vm.toggleFavorite(user)),
              );
            },
          ),
        ),
      },
    ),
  );
}
