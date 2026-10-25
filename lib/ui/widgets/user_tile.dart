import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/models/user.dart';

/// Fila de usuario compartida por Usuarios y Favoritos: nombre, correo,
/// empresa y una estrella que sigue a [favoriteIds].
class UserTile extends StatelessWidget {
  const UserTile({
    super.key,
    required this.user,
    required this.favoriteIds,
    required this.starKey,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final User user;
  final ValueListenable<Set<int>> favoriteIds;
  final Key starKey;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    isThreeLine: true,
    leading: CircleAvatar(
      child: Text(user.name.isEmpty ? '?' : user.name.characters.first),
    ),
    title: Text(user.name),
    subtitle: Text('${user.email}\n${user.companyName}'),
    trailing: FavoriteButton(
      key: starKey,
      favoriteIds: favoriteIds,
      userId: user.id,
      onPressed: onToggleFavorite,
    ),
  );
}

/// Estrella de favorito con tooltip y etiqueta de accesibilidad.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.favoriteIds,
    required this.userId,
    required this.onPressed,
  });

  final ValueListenable<Set<int>> favoriteIds;
  final int userId;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: favoriteIds,
    builder: (context, ids, _) {
      final favorite = ids.contains(userId);
      return IconButton(
        onPressed: onPressed,
        tooltip: favorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
        icon: Icon(
          favorite ? Icons.star : Icons.star_border,
          color: favorite ? Theme.of(context).colorScheme.primary : null,
        ),
      );
    },
  );
}

/// Espera el cambio de favorito y muestra el SnackBar si la pantalla sigue
/// abierta.
Future<void> toggleWithFeedback(
  BuildContext context,
  Future<bool?> toggle,
) async {
  final nowFavorite = await toggle;
  if (context.mounted) showFavoriteSnackBar(context, nowFavorite);
}

/// Mensaje tras tocar una estrella; `null` significa que no se pudo guardar.
void showFavoriteSnackBar(BuildContext context, bool? nowFavorite) {
  final text = switch (nowFavorite) {
    true => 'Agregado a favoritos',
    false => 'Quitado de favoritos',
    null => 'No se pudo guardar el favorito.',
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
