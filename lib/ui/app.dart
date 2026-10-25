import 'package:flutter/material.dart';

import '../data/user_repository.dart';
import 'favorites/favorites_screen.dart';
import 'users/users_screen.dart';

const _seedColor = Colors.indigo;

/// Raíz de la app: tema claro/oscuro y navegación inferior.
class DirectorioApp extends StatelessWidget {
  const DirectorioApp({super.key, required this.repo});

  final UserRepository repo;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Directorio',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: _seedColor),
    darkTheme: ThemeData(
      colorSchemeSeed: _seedColor,
      brightness: Brightness.dark,
    ),
    home: HomeShell(repo: repo),
  );
}

/// Pestañas Usuarios y Favoritos. [IndexedStack] conserva el estado de
/// cada pestaña (lista cargada, posición del scroll) al cambiar de una a
/// otra.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.repo});

  final UserRepository repo;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _index,
      children: [
        UsersScreen(repo: widget.repo),
        FavoritesScreen(repo: widget.repo),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      destinations: const [
        NavigationDestination(
          key: ValueKey('nav.users'),
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Usuarios',
        ),
        NavigationDestination(
          key: ValueKey('nav.favorites'),
          icon: Icon(Icons.star_border),
          selectedIcon: Icon(Icons.star),
          label: 'Favoritos',
        ),
      ],
    ),
  );
}
