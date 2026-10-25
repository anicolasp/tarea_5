import 'package:flutter/material.dart';

import '../ui_state.dart' show offlineMessage;

/// Vistas de estado compartidas por lista, detalle y favoritos.
///
/// Son desplazables para caber en pantallas pequeñas y para que
/// `RefreshIndicator` funcione aunque no haya lista.

class LoadingView extends StatelessWidget {
  const LoadingView({super.key = const ValueKey('state.loading')});

  @override
  Widget build(BuildContext context) => const _CenteredState(
    children: [
      CircularProgressIndicator(),
      SizedBox(height: 16),
      Text('Cargando…'),
    ],
  );
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key = const ValueKey('state.empty'),
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) => _CenteredState(
    children: [
      _StateIcon(Icons.inbox_outlined),
      const SizedBox(height: 16),
      Text(message, textAlign: TextAlign.center),
    ],
  );
}

class OfflineView extends StatelessWidget {
  const OfflineView({
    super.key = const ValueKey('state.offline'),
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _CenteredState(
    children: [
      _StateIcon(Icons.wifi_off),
      const SizedBox(height: 16),
      Text(
        offlineMessage,
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      const Text(
        'Revisa tu conexión e inténtalo de nuevo.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      _RetryButton(onRetry),
    ],
  );
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key = const ValueKey('state.error'),
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _CenteredState(
    children: [
      _StateIcon(Icons.error_outline, error: true),
      const SizedBox(height: 16),
      Text(
        'Ocurrió un error',
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 24),
      _RetryButton(onRetry),
    ],
  );
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // Dentro de una Column o lista (p. ej. la sección de publicaciones)
        // la altura no tiene límite: se muestra tal cual, sin scroll propio.
        if (!constraints.hasBoundedHeight) return content;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: content,
          ),
        );
      },
    );
  }
}

class _StateIcon extends StatelessWidget {
  const _StateIcon(this.icon, {this.error = false});

  final IconData icon;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Icon(
      icon,
      size: 56,
      color: error ? colors.error : colors.onSurfaceVariant,
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton(this.onRetry);

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
    key: const ValueKey('state.retry'),
    onPressed: onRetry,
    icon: const Icon(Icons.refresh),
    label: const Text('Reintentar'),
  );
}
