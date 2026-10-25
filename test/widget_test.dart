import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarea_5/ui/app.dart';

import 'ui/fake_repository.dart';

void main() {
  testWidgets('the app starts on Usuarios with both tabs', (tester) async {
    final repo = FakeRepository()..usersResult = [user(1, 'Leanne')];

    await tester.pumpWidget(DirectorioApp(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Leanne 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('nav.users')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav.favorites')), findsOneWidget);
  });
}
