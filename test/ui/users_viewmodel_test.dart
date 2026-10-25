import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tarea_5/data/remote/api_client.dart';
import 'package:tarea_5/ui/ui_state.dart';
import 'package:tarea_5/ui/users/users_viewmodel.dart';

import 'fake_repository.dart';

void main() {
  late FakeRepository repo;
  late UsersViewModel vm;

  setUp(() {
    repo = FakeRepository();
    vm = UsersViewModel(repo);
  });

  tearDown(() {
    if (!vm.isDisposed) vm.dispose();
  });

  test('starts in Loading', () {
    expect(vm.state, isA<Loading>());
  });

  test('load with users ends in Success', () async {
    repo.usersResult = [user(1), user(2)];

    await vm.load();

    expect((vm.state as Success).data, hasLength(2));
  });

  test('load with an empty list ends in Empty', () async {
    await vm.load();

    expect(vm.state, isA<Empty>());
  });

  test('NoInternetException ends in Offline', () async {
    repo.usersResult = const NoInternetException();

    await vm.load();

    expect(vm.state, isA<Offline>());
  });

  test('ApiException ends in Failure with its message', () async {
    repo.usersResult = const ApiException('El servidor respondió 500.');

    await vm.load();

    expect((vm.state as Failure).message, 'El servidor respondió 500.');
  });

  test('any other error ends in Failure with the generic message', () async {
    repo.usersResult = StateError('db');

    await vm.load();

    expect((vm.state as Failure).message, genericErrorMessage);
  });

  test('load shows Loading again before the result', () async {
    repo.usersResult = [user(1)];
    await vm.load();
    final states = <Object>[];
    vm.addListener(() => states.add(vm.state));

    await vm.load();

    expect(states, [isA<Loading>(), isA<Success>()]);
  });

  test('refresh keeps data visible and never shows Loading', () async {
    repo.usersResult = [user(1)];
    await vm.load();
    final states = <Object>[];
    vm.addListener(() => states.add(vm.state));

    repo.usersResult = [user(1), user(2)];
    await vm.refresh();

    expect(states.whereType<Loading>(), isEmpty);
    expect((vm.state as Success).data, hasLength(2));
  });

  test('a failed refresh keeps the data and reports it once', () async {
    repo.usersResult = [user(1)];
    await vm.load();

    repo.usersResult = const NoInternetException();
    await vm.refresh();

    expect((vm.state as Success).data, hasLength(1));
    expect(vm.takeRefreshError(), 'Sin conexión a Internet');
    expect(vm.takeRefreshError(), isNull);
  });

  test('a stale response arriving after a newer one is ignored', () async {
    final firstGate = Completer<void>();
    repo.usersGates.addAll([firstGate, Completer()..complete()]);

    repo.usersResult = [user(1)];
    final first = vm.load();
    repo.usersResult = [user(1), user(2)];
    await vm.load();
    // The first (older) request finishes last.
    firstGate.complete();
    await first;

    expect((vm.state as Success).data, hasLength(2));
  });

  test('dispose before the response arrives does not throw', () async {
    final gate = Completer<void>();
    repo.usersGates.add(gate);
    repo.usersResult = [user(1)];
    final pending = vm.load();

    vm.dispose();
    gate.complete();

    await expectLater(pending, completes);
  });

  test('toggleFavorite returns the new state, or null on error', () async {
    expect(await vm.toggleFavorite(user(1)), isTrue);
    expect(vm.favoriteIds.value, {1});

    repo.toggleError = StateError('db');
    expect(await vm.toggleFavorite(user(1)), isNull);
  });
}
