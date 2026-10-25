import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Conecta una pantalla con el ciclo de vida de la app (≈ Activity en
/// Android) para reintentar la carga al volver a primer plano.
///
/// | Android     | Flutter                          | Acción                     |
/// |-------------|----------------------------------|----------------------------|
/// | onCreate    | `initState`                      | registra el observador     |
/// | onPause     | `AppLifecycleState.hidden/paused`| marca que se fue al fondo  |
/// | onResume    | `AppLifecycleState.resumed`      | [retryIfFailed] si se ve   |
/// | onDestroy   | `dispose`                        | quita el observador        |
///
/// Solo reintenta si la app pasó de verdad a segundo plano (bajar la barra
/// de notificaciones va de `inactive` a `resumed` y no cuenta) y si la
/// pantalla está visible (no tapada por otra ruta ni en una pestaña oculta).
mixin RetryOnResume<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  bool _wentToBackground = false;

  /// Nombre de la pantalla en los logs de depuración.
  String get lifecycleTag;

  /// Reintenta la carga si la última falló; devuelve si reintentó.
  bool retryIfFailed();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _isVisible =>
      (ModalRoute.of(context)?.isCurrent ?? true) && Visibility.of(context);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        // ≈ onPause: no se hace trabajo de red; solo se recuerda que la app
        // se fue al fondo.
        if (!_wentToBackground) _log('paused');
        _wentToBackground = true;
      case AppLifecycleState.resumed:
        if (!_wentToBackground) return;
        _wentToBackground = false;
        if (!mounted || !_isVisible) return _log('resumed (no visible)');
        _log(retryIfFailed() ? 'resumed → reintento' : 'resumed');
      default:
        break;
    }
  }

  void _log(String event) {
    if (kDebugMode) debugPrint('$lifecycleTag: $event');
  }
}
