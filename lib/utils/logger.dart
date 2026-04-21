import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class AppLogger {
  static void info(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'INFO');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'WARNING', level: 900);
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      developer.log(
        message,
        name: 'ERROR',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  static void debug(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'DEBUG');
    }
  }
}
