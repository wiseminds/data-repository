import 'package:data_repository/data_repository.dart';
import 'package:example/env.dart';
import 'package:example/modules/post/data/post_api.dart';
import 'package:example/modules/post/repository/post_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data/local/hive_repository.dart';

/// How the cached data is persisted.
///
/// Each option is a different implementation of the same [LocalRepository]
/// interface, and nothing above that interface knows which one is in use.
enum CacheBackend {
  /// Ships with the package. Survives restarts, no extra dependency.
  file,

  /// A third-party store, adapted to the interface by [HiveRepository].
  hive,

  /// In-memory only. Ideal for tests and for `flutter run` experiments.
  memory,
}

/// The composition root.
///
/// This is the single place in the app that names concrete implementations.
/// Everything else -- repositories, cubits, widgets -- depends only on the
/// abstractions registered here, which is what makes them swappable and
/// testable.
///
///     abstraction              implementations
///     ------------------------ ----------------------------------------
///     LocalRepository          FileLocalRepository | HiveRepository |
///                              MapRepository
///     ApiProvider              HttpApiProvider | your own transport
///     ApiInterceptor           Header | Json | Logging | your own
class DependencyInjection {
  static final locator = GetIt.I;

  static GlobalKey<NavigatorState> navigator =
      GetIt.I<GlobalKey<NavigatorState>>();

  /// Wires the object graph.
  ///
  /// Pass [cache] or [provider] to substitute an implementation -- a widget
  /// test can inject a `MapRepository` and an `HttpApiProvider` backed by a
  /// `MockClient` without touching a line of application code.
  static Future<void> bootstrap({
    CacheBackend cache = CacheBackend.file,
    ApiProvider? provider,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    // The package writes nothing to the console unless given a logger.
    if (kDebugMode) ApiConfig().logger = debugPrint;

    locator.registerSingleton<Env>(kDebugMode ? Development() : Production());

    // --- Inversion point 1: where cached data lives -----------------------
    locator.registerSingleton<LocalRepository>(await _localRepository(cache));

    // --- Inversion point 2: how requests travel ---------------------------
    locator.registerSingleton<ApiProvider>(provider ?? HttpApiProvider());

    locator.registerSingleton<RemoteRepository>(
      RemoteRepository(
        locator<ApiProvider>(),
        'Something went wrong',
        // Retry transient failures with backoff, everywhere, by default.
        const RetryPolicy(maxAttempts: 3),
      ),
    );

    // --- Constructor injection, not service location ----------------------
    // The repository is handed its collaborators; it never reaches into the
    // locator itself, so it can be constructed directly in a test.
    locator.registerLazySingleton<PostApi>(
      () => PostApi(baseUrl: locator<Env>().baseUrl),
    );
    locator.registerLazySingleton<PostRepository>(
      () => PostRepository(
        locator<LocalRepository>(),
        locator<RemoteRepository>(),
        locator<PostApi>(),
      ),
    );

    await locator.allReady();
  }

  static Future<LocalRepository> _localRepository(CacheBackend backend) async {
    switch (backend) {
      case CacheBackend.hive:
        await Hive.initFlutter();
        return HiveRepository();
      case CacheBackend.memory:
        return MapRepository();
      case CacheBackend.file:
        return FileLocalRepository();
    }
  }

  /// Tears the graph down; useful between tests.
  static Future<void> reset() async {
    if (locator.isRegistered<RemoteRepository>()) {
      locator<RemoteRepository>().close();
    }
    await locator.reset();
  }
}
