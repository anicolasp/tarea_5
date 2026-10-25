import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarea_5/ui/widgets/state_views.dart';

Future<void> _pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

void main() {
  testWidgets('LoadingView shows the spinner and text', (tester) async {
    await _pump(tester, const LoadingView());

    expect(find.byKey(const ValueKey('state.loading')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Cargando…'), findsOneWidget);
  });

  testWidgets('EmptyView shows the message from the caller', (tester) async {
    await _pump(tester, const EmptyView(message: 'Aún no tienes favoritos.'));

    expect(find.byKey(const ValueKey('state.empty')), findsOneWidget);
    expect(find.text('Aún no tienes favoritos.'), findsOneWidget);
  });

  testWidgets('OfflineView shows the exact copy and retries', (tester) async {
    var retries = 0;
    await _pump(tester, OfflineView(onRetry: () => retries++));

    expect(find.byKey(const ValueKey('state.offline')), findsOneWidget);
    expect(find.text('Sin conexión a Internet'), findsOneWidget);
    expect(
      find.text('Revisa tu conexión e inténtalo de nuevo.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('state.retry')));
    expect(retries, 1);
  });

  testWidgets('ErrorView shows the message and retries', (tester) async {
    var retries = 0;
    await _pump(
      tester,
      ErrorView(
        message: 'El servidor respondió 500.',
        onRetry: () => retries++,
      ),
    );

    expect(find.byKey(const ValueKey('state.error')), findsOneWidget);
    expect(find.text('Ocurrió un error'), findsOneWidget);
    expect(find.text('El servidor respondió 500.'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    expect(retries, 1);
  });

  testWidgets('views work inside a list with unbounded height', (tester) async {
    await _pump(
      tester,
      ListView(
        children: [
          const Text('Cabecera del usuario'),
          OfflineView(onRetry: () {}),
          const LoadingView(),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Sin conexión a Internet'), findsOneWidget);
  });

  testWidgets('views fit a small screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(tester, OfflineView(onRetry: () {}));

    expect(tester.takeException(), isNull);
  });
}
