import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarea_5/data/remote/api_client.dart';
import 'package:tarea_5/ui/app.dart';
import 'package:tarea_5/ui/detail/user_detail_screen.dart';
import 'package:tarea_5/ui/users/users_screen.dart';

import 'fake_repository.dart';

Future<void> _lifecycle(WidgetTester tester, AppLifecycleState state) async {
  tester.binding.handleAppLifecycleStateChanged(state);
  await tester.pumpAndSettle();
}

/// Simula que la app pasa a segundo plano y vuelve (≈ onPause → onResume).
Future<void> _backgroundAndResume(WidgetTester tester) async {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    await _lifecycle(tester, state);
  }
}

Future<void> _pumpUsers(WidgetTester tester, FakeRepository repo) async {
  await tester.pumpWidget(MaterialApp(home: UsersScreen(repo: repo)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('initState loads the users once', (tester) async {
    final repo = FakeRepository()..usersResult = [user(1)];

    await _pumpUsers(tester, repo);

    expect(repo.fetchUsersCalls, 1);
  });

  testWidgets('resumed retries when the list is Offline', (tester) async {
    final repo = FakeRepository()..usersResult = const NoInternetException();
    await _pumpUsers(tester, repo);
    expect(find.text('Sin conexión a Internet'), findsOneWidget);

    // The network comes back while the app is in the background.
    repo.usersResult = [user(1, 'Leanne')];
    await _backgroundAndResume(tester);

    expect(repo.fetchUsersCalls, 2);
    expect(find.text('Leanne 1'), findsOneWidget);
  });

  testWidgets('resumed retries when the list is Failure', (tester) async {
    final repo = FakeRepository()
      ..usersResult = const ApiException('El servidor respondió 500.');
    await _pumpUsers(tester, repo);

    repo.usersResult = [user(1)];
    await _backgroundAndResume(tester);

    expect(repo.fetchUsersCalls, 2);
  });

  testWidgets('resumed does not reload data that is already shown', (
    tester,
  ) async {
    final repo = FakeRepository()..usersResult = [user(1)];
    await _pumpUsers(tester, repo);

    await _backgroundAndResume(tester);

    expect(repo.fetchUsersCalls, 1);
  });

  testWidgets('paused does no network work', (tester) async {
    final repo = FakeRepository()..usersResult = const NoInternetException();
    await _pumpUsers(tester, repo);

    await _lifecycle(tester, AppLifecycleState.inactive);
    await _lifecycle(tester, AppLifecycleState.hidden);
    await _lifecycle(tester, AppLifecycleState.paused);

    expect(repo.fetchUsersCalls, 1);
  });

  testWidgets('after dispose, resumed no longer triggers a load', (
    tester,
  ) async {
    final repo = FakeRepository()..usersResult = const NoInternetException();
    await _pumpUsers(tester, repo);

    await tester.pumpWidget(const SizedBox());
    await _backgroundAndResume(tester);

    expect(repo.fetchUsersCalls, 1);
  });

  testWidgets('detail retries offline posts on resumed', (tester) async {
    final repo = FakeRepository()..postsResult = const NoInternetException();
    await tester.pumpWidget(
      MaterialApp(
        home: UserDetailScreen(repo: repo, user: user(1)),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.fetchPostsCalls, 1);

    repo.postsResult = [post(1, 1)];
    await _backgroundAndResume(tester);

    expect(repo.fetchPostsCalls, 2);
    expect(find.text('Título 1'), findsOneWidget);
  });

  testWidgets('inactive → resumed without going to background does not '
      'retry (e.g. notification shade)', (tester) async {
    final repo = FakeRepository()..usersResult = const NoInternetException();
    await _pumpUsers(tester, repo);

    await _lifecycle(tester, AppLifecycleState.inactive);
    await _lifecycle(tester, AppLifecycleState.resumed);

    expect(repo.fetchUsersCalls, 1);
  });

  testWidgets('the retry keeps the offline message instead of a spinner', (
    tester,
  ) async {
    final repo = FakeRepository()..usersResult = const NoInternetException();
    await _pumpUsers(tester, repo);
    final gate = Completer<void>();
    repo.usersGates.addAll([Completer()..complete(), gate]);

    await _backgroundAndResume(tester);
    // The request is still in flight.
    expect(find.text('Sin conexión a Internet'), findsOneWidget);
    expect(find.byKey(const ValueKey('state.loading')), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
    expect(repo.fetchUsersCalls, 2);
  });

  testWidgets('a list covered by another route does not retry', (tester) async {
    final repo = FakeRepository()..usersResult = const NoInternetException();
    await _pumpUsers(tester, repo);
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.push(MaterialPageRoute<void>(builder: (_) => const Text('Encima')));
    await tester.pumpAndSettle();

    await _backgroundAndResume(tester);

    expect(repo.fetchUsersCalls, 1);
  });

  testWidgets('the hidden Usuarios tab does not retry', (tester) async {
    final repo = FakeRepository()..usersResult = const NoInternetException();
    await tester.pumpWidget(DirectorioApp(repo: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav.favorites')));
    await tester.pumpAndSettle();

    await _backgroundAndResume(tester);

    expect(repo.fetchUsersCalls, 1);
  });

  testWidgets('detail retries posts that failed with an API error', (
    tester,
  ) async {
    final repo = FakeRepository()
      ..postsResult = const ApiException('El servidor respondió 500.');
    await tester.pumpWidget(
      MaterialApp(
        home: UserDetailScreen(repo: repo, user: user(1)),
      ),
    );
    await tester.pumpAndSettle();

    repo.postsResult = [post(1, 1)];
    await _backgroundAndResume(tester);

    expect(repo.fetchPostsCalls, 2);
  });

  testWidgets('a closed detail stops observing the lifecycle', (tester) async {
    final repo = FakeRepository()
      ..usersResult = [user(1)]
      ..postsResult = const NoInternetException();
    await _pumpUsers(tester, repo);
    await tester.tap(find.text('Usuario 1'));
    await tester.pumpAndSettle();
    expect(repo.fetchPostsCalls, 1);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await _backgroundAndResume(tester);

    expect(repo.fetchPostsCalls, 1);
  });

  testWidgets('detail does not reload posts already shown', (tester) async {
    final repo = FakeRepository()..postsResult = [post(1, 1)];
    await tester.pumpWidget(
      MaterialApp(
        home: UserDetailScreen(repo: repo, user: user(1)),
      ),
    );
    await tester.pumpAndSettle();

    await _backgroundAndResume(tester);

    expect(repo.fetchPostsCalls, 1);
  });
}
