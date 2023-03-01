import 'dart:io';

import 'package:data_repository/local/local_repository.dart';
import 'package:data_repository/remote/provider/providers/http_api_provider.dart';
import 'package:data_repository/remote/provider/providers/http_override.dart';
import 'package:data_repository/remote/remote_repository.dart';
import 'package:example/env.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data/local/hive_repository.dart';

class DependencyInjection {
  static final locator = GetIt.I;
  static GlobalKey<NavigatorState> navigator =
      GetIt.I<GlobalKey<NavigatorState>>();

  /// registers necessary dependencies
  static bootstrap() async {
    WidgetsFlutterBinding.ensureInitialized();
    locator.registerSingleton<Env>(kDebugMode ? Development() : Production());

    HttpOverrides.global = MyHttpOverrides();
    await Hive.initFlutter();

    locator.registerSingleton<LocalRepository>(HiveRepository());
    // locator.registerSingleton<BiometricsService>(LocalAuth());
    locator.registerSingleton<RemoteRepository>(
        RemoteRepository(HttpApiProvider(), 'An error occured'));

    await locator.allReady();
  }
}
