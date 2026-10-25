import 'package:flutter/foundation.dart';

import '../data/remote/api_client.dart';

/// Estado de una pantalla que carga datos.
///
/// `load()` → [Loading] → [Success] | [Empty] | [Offline] | [Failure].
/// Se llama [Failure] (y no `Error`) para no tapar la clase `Error` de Dart.
sealed class UiState<T> {
  const UiState();
}

class Loading<T> extends UiState<T> {
  const Loading();
}

class Success<T> extends UiState<T> {
  const Success(this.data);

  final T data;
}

class Empty<T> extends UiState<T> {
  const Empty();
}

/// Sin conexión a Internet.
class Offline<T> extends UiState<T> {
  const Offline();
}

class Failure<T> extends UiState<T> {
  const Failure(this.message);

  final String message;
}

const genericErrorMessage = 'No se pudo cargar la información.';
const offlineMessage = 'Sin conexión a Internet';

/// Convierte cualquier error en un estado de la UI, para que ninguna
/// excepción salga de un ViewModel.
UiState<T> uiStateFromError<T>(Object error) => switch (error) {
  NoInternetException() => const Offline(),
  ApiException(:final message) => Failure(message),
  _ => const Failure(genericErrorMessage),
};

/// Ejecuta [fetch] y devuelve [Success], [Empty] o el estado del error.
Future<UiState<List<T>>> fetchState<T>(Future<List<T>> Function() fetch) async {
  try {
    final items = await fetch();
    return items.isEmpty ? Empty<List<T>>() : Success<List<T>>(items);
  } catch (e) {
    return uiStateFromError(e);
  }
}

/// Ejecuta un cambio de favorito; devuelve `null` si falló (p. ej. SQLite),
/// en vez de lanzar.
Future<bool?> safeToggle(Future<bool> Function() toggle) async {
  try {
    return await toggle();
  } catch (e) {
    debugPrint('toggleFavorite: $e');
    return null;
  }
}

/// Ignora [notifyListeners] después de [dispose]: una respuesta que llega
/// cuando la pantalla ya se cerró no lanza excepción.
mixin SafeNotifier on ChangeNotifier {
  bool _disposed = false;

  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
