import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarea_5/data/models/user.dart';
import 'package:tarea_5/data/remote/api_client.dart';
import 'package:tarea_5/ui/app.dart';

import 'fake_repository.dart';

Future<FakeRepository> _pumpApp(
  WidgetTester tester, {
  Object? users,
  Object? posts,
}) async {
  final repo = FakeRepository()
    ..usersResult = users ?? [user(1, 'Leanne'), user(2, 'Ervin')]
    ..postsResult = posts ?? [post(1, 1), post(2, 1)];
  await tester.pumpWidget(DirectorioApp(repo: repo));
  await tester.pumpAndSettle();
  return repo;
}

Finder _key(String key) => find.byKey(ValueKey(key));

void main() {
  testWidgets('the list shows name, email and company', (tester) async {
    await _pumpApp(tester);

    expect(_key('users.list'), findsOneWidget);
    expect(find.text('Leanne 1'), findsOneWidget);
    expect(find.text('u1@example.com\nEmpresa 1'), findsOneWidget);
  });

  testWidgets('no internet shows OfflineView and retry reloads', (
    tester,
  ) async {
    final repo = await _pumpApp(tester, users: const NoInternetException());

    expect(_key('state.offline'), findsOneWidget);
    expect(find.text('Sin conexión a Internet'), findsOneWidget);

    repo.usersResult = [user(1, 'Leanne')];
    await tester.tap(_key('state.retry'));
    await tester.pumpAndSettle();

    expect(find.text('Leanne 1'), findsOneWidget);
  });

  testWidgets('an API error shows ErrorView with the message', (tester) async {
    await _pumpApp(
      tester,
      users: const ApiException('El servidor respondió 500.'),
    );

    expect(_key('state.error'), findsOneWidget);
    expect(find.text('El servidor respondió 500.'), findsOneWidget);
  });

  testWidgets('tapping a user opens the detail with posts', (tester) async {
    await _pumpApp(tester);

    await tester.tap(_key('users.item.1'));
    await tester.pumpAndSettle();

    expect(find.text('Publicaciones'), findsOneWidget);
    expect(find.text('Título 1'), findsOneWidget);
    expect(find.text('Empresa 1'), findsOneWidget);
  });

  testWidgets('the detail header stays visible when posts are offline', (
    tester,
  ) async {
    await _pumpApp(tester, posts: const NoInternetException());

    await tester.tap(_key('users.item.1'));
    await tester.pumpAndSettle();

    expect(find.text('u1@example.com'), findsOneWidget);
    expect(_key('state.offline'), findsOneWidget);
  });

  testWidgets('a user with no posts shows the empty message', (tester) async {
    await _pumpApp(tester, posts: const <Never>[]);

    await tester.tap(_key('users.item.1'));
    await tester.pumpAndSettle();

    expect(find.text('Este usuario no tiene publicaciones.'), findsOneWidget);
  });

  testWidgets('the star syncs across list, detail and favorites', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(_key('users.favorite.1'));
    await tester.pumpAndSettle();
    expect(find.text('Agregado a favoritos'), findsOneWidget);

    // Detail shows the filled star.
    await tester.tap(_key('users.item.1'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: _key('detail.favorite'),
        matching: find.byIcon(Icons.star),
      ),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Favorites tab lists the user.
    await tester.tap(_key('nav.favorites'));
    await tester.pumpAndSettle();
    expect(_key('favorites.item.1'), findsOneWidget);

    // Removing it there empties the tab and clears the list star.
    await tester.tap(_key('favorites.favorite.1'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Aún no tienes favoritos. Toca ☆ en un usuario para guardarlo.',
      ),
      findsOneWidget,
    );
    // The Usuarios tab is offstage inside the IndexedStack.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('users.favorite.1'), skipOffstage: false),
        matching: find.byIcon(Icons.star_border, skipOffstage: false),
      ),
      findsOneWidget,
    );
  });

  testWidgets('favorites work while the API is offline', (tester) async {
    final repo = await _pumpApp(tester, users: const NoInternetException());
    await repo.toggleFavorite(user(3, 'Clementine'));

    await tester.tap(_key('nav.favorites'));
    await tester.pumpAndSettle();

    expect(find.text('Clementine 3'), findsOneWidget);
  });

  testWidgets('a user with an empty name still renders', (tester) async {
    await _pumpApp(
      tester,
      users: [
        User(
          id: 9,
          name: '',
          username: '',
          email: 'x@example.com',
          phone: '',
          website: '',
          companyName: 'Empresa',
          city: '',
        ),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('a failed favorite write shows a message, no crash', (
    tester,
  ) async {
    final repo = await _pumpApp(tester);
    repo.toggleError = StateError('db');

    await tester.tap(_key('users.favorite.1'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo guardar el favorito.'), findsOneWidget);
  });
}
