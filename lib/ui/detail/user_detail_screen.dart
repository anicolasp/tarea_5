import 'package:flutter/material.dart';

import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/user_repository.dart';
import '../ui_state.dart';
import '../widgets/state_views.dart';
import '../widgets/user_tile.dart';
import 'detail_viewmodel.dart';

/// Abre el detalle de [user] desde Usuarios o Favoritos.
Future<void> openUserDetail(
  BuildContext context,
  UserRepository repo,
  User user,
) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => UserDetailScreen(repo: repo, user: user),
  ),
);

/// Requisito 2: datos del usuario y sus publicaciones.
///
/// La cabecera usa el [User] ya cargado, así que se ve aunque no haya red;
/// solo la sección de publicaciones depende de la API.
class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key, required this.repo, required this.user});

  final UserRepository repo;
  final User user;

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late final DetailViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = DetailViewModel(widget.repo, widget.user);
    _vm.loadPosts();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.user.name),
      actions: [
        FavoriteButton(
          key: const ValueKey('detail.favorite'),
          favoriteIds: _vm.favoriteIds,
          userId: widget.user.id,
          onPressed: () => toggleWithFeedback(context, _vm.toggleFavorite()),
        ),
      ],
    ),
    body: ListenableBuilder(
      listenable: _vm,
      builder: (context, _) => ListView(
        children: [
          _UserCard(user: widget.user),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Publicaciones',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          KeyedSubtree(
            key: const ValueKey('detail.posts'),
            child: switch (_vm.postsState) {
              Loading() => const LoadingView(),
              Empty() => const EmptyView(
                message: 'Este usuario no tiene publicaciones.',
              ),
              Offline() => OfflineView(onRetry: _vm.loadPosts),
              Failure(:final message) => ErrorView(
                message: message,
                onRetry: _vm.loadPosts,
              ),
              Success(data: final posts) => Column(
                children: [for (final post in posts) _PostTile(post: post)],
              ),
            },
          ),
        ],
      ),
    ),
  );
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.all(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          for (final (icon, value) in [
            (Icons.email_outlined, user.email),
            (Icons.phone_outlined, user.phone),
            (Icons.language, user.website),
            (Icons.business_outlined, user.companyName),
            (Icons.location_city_outlined, user.city),
          ])
            if (value.isNotEmpty)
              ListTile(dense: true, leading: Icon(icon), title: Text(value)),
        ],
      ),
    ),
  );
}

class _PostTile extends StatelessWidget {
  const _PostTile({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        title: Text(post.title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(post.body),
        ),
      ),
      const Divider(height: 1, indent: 16, endIndent: 16),
    ],
  );
}
