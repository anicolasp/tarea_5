import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:sqflite/sqflite.dart' show inMemoryDatabasePath;

import 'data/local/favorites_db.dart';
import 'data/remote/api_client.dart';
import 'data/user_repository.dart';
import 'ui/app.dart';

Future<void> main() async {
  if (kDebugMode) {
    final logs = PrintLogCollector();
    MarionetteBinding.ensureInitialized(
      MarionetteConfiguration(logCollector: logs),
    );
    // Lets Marionette read debugPrint output (e.g. ignored rows, failed
    // favorite writes) while driving the app.
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      original(message, wrapWidth: wrapWidth);
      if (message != null) logs.addLog(message);
    };
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }

  final repo = UserRepository(ApiClient(), await _openFavorites());
  try {
    await repo.init();
  } catch (e) {
    // The app still works: toggleFavorite reads the state from SQLite.
    debugPrint('UserRepository.init: $e');
  }

  final app = DirectorioApp(repo: repo);
  // Lets Marionette override theme and text scale during visual checks.
  // Same condition as MarionetteBinding above, so profile builds stay clean.
  runApp(kDebugMode ? MarionetteDeviceConfig(child: app) : app);
}

/// Opens the favorites database. If the file cannot be opened (corrupt,
/// disk full), falls back to an in-memory database so the app still
/// starts; favorites then last only for this session.
Future<FavoritesDb> _openFavorites() async {
  try {
    return await FavoritesDb.open();
  } catch (e) {
    debugPrint('FavoritesDb.open: $e — using an in-memory database');
    return FavoritesDb.open(path: inMemoryDatabasePath);
  }
}
