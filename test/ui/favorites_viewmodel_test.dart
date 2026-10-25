import 'package:flutter_test/flutter_test.dart';
import 'package:tarea_5/data/remote/api_client.dart';
import 'package:tarea_5/ui/favorites/favorites_viewmodel.dart';
import 'package:tarea_5/ui/ui_state.dart';

import 'fake_repository.dart';

void main() {
  late FakeRepository repo;
  late FavoritesViewModel vm;

  setUp(() {
    repo = FakeRepository();
    vm = FavoritesViewModel(repo);
  });

  tearDown(() {
    if (!vm.isDisposed) vm.dispose();
  });

  test('no favorites ends in Empty', () async {
    await vm.load();

    expect(vm.state, isA<Empty>());
  });

  test('works with no internet because it only reads SQLite', () async {
    repo.usersResult = const NoInternetException();
    repo.postsResult = const NoInternetException();
    await repo.toggleFavorite(user(1));

    await vm.load();

    expect((vm.state as Success).data.single.id, 1);
  });

  test('reloads when a star changes on another screen', () async {
    await vm.load();
    expect(vm.state, isA<Empty>());

    await repo.toggleFavorite(user(2));
    await pumpEventQueue();

    expect((vm.state as Success).data.single.id, 2);
  });

  test('a database error ends in Failure, never Offline', () async {
    repo.favoritesError = StateError('db');

    await vm.load();

    expect((vm.state as Failure).message, genericErrorMessage);
  });

  test('a failed background reload keeps the visible list', () async {
    await repo.toggleFavorite(user(1));
    await vm.load();

    repo.favoritesError = StateError('db');
    await vm.load();

    expect((vm.state as Success).data.single.id, 1);
  });

  test('removing the last favorite goes back to Empty', () async {
    await repo.toggleFavorite(user(1));
    await vm.load();

    expect(await vm.toggleFavorite(user(1)), isFalse);
    await pumpEventQueue();

    expect(vm.state, isA<Empty>());
  });
}
