import 'package:flutter_test/flutter_test.dart';
import 'package:tarea_5/data/remote/api_client.dart';
import 'package:tarea_5/ui/detail/detail_viewmodel.dart';
import 'package:tarea_5/ui/ui_state.dart';

import 'fake_repository.dart';

void main() {
  late FakeRepository repo;
  late DetailViewModel vm;

  setUp(() {
    repo = FakeRepository();
    vm = DetailViewModel(repo, user(1));
  });

  tearDown(() {
    if (!vm.isDisposed) vm.dispose();
  });

  test('loadPosts with posts ends in Success', () async {
    repo.postsResult = [post(1, 1), post(2, 1)];

    await vm.loadPosts();

    expect((vm.postsState as Success).data, hasLength(2));
  });

  test('a user with no posts ends in Empty', () async {
    await vm.loadPosts();

    expect(vm.postsState, isA<Empty>());
  });

  test('no internet ends in Offline while the user stays available', () async {
    repo.postsResult = const NoInternetException();

    await vm.loadPosts();

    expect(vm.postsState, isA<Offline>());
    expect(vm.user.name, 'Usuario 1');
  });

  test('ApiException ends in Failure', () async {
    repo.postsResult = const ApiException('El servidor respondió 404.');

    await vm.loadPosts();

    expect(vm.postsState, isA<Failure>());
  });

  test('isFavorite follows the repository and notifies', () async {
    var notified = 0;
    vm.addListener(() => notified++);

    expect(await vm.toggleFavorite(), isTrue);

    expect(vm.isFavorite, isTrue);
    expect(notified, greaterThan(0));
  });

  test('a star changed elsewhere updates isFavorite', () async {
    await repo.toggleFavorite(user(1));

    expect(vm.isFavorite, isTrue);
  });

  test('dispose stops listening to favoriteIds', () async {
    vm.dispose();

    await repo.toggleFavorite(user(1));

    expect(repo.favoriteIds.value, {1});
  });
}
