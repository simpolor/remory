import 'package:flutter/foundation.dart' show kDebugMode;

class Env {
  static const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'prod');

  static bool get isLocal => appEnv == 'local' || kDebugMode;
  static bool get isDev   => appEnv == 'dev';
  static bool get isProd  => appEnv == 'prod';
}