// ============================================================================
// FILE: lib/core/logger.dart
// Conditional logging utility - only logs in debug mode
// ============================================================================

import 'package:flutter/foundation.dart';

/// App logger that only outputs in debug mode.
///
/// Usage:
/// ```dart
/// AppLogger.debug('Processing message');
/// AppLogger.info('Import complete');
/// AppLogger.warning('Missing data');
/// AppLogger.error('Failed to parse', error: e, stackTrace: stackTrace);
/// ```
class AppLogger {
  AppLogger._();

  /// Log debug-level message (only in debug mode)
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('$prefix$message');
    }
  }

  /// Log info-level message (only in debug mode)
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('ℹ️ $prefix$message');
    }
  }

  /// Log warning-level message (only in debug mode)
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('⚠️ $prefix$message');
    }
  }

  /// Log error-level message (only in debug mode)
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('❌ $prefix$message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// Log success message (only in debug mode)
  static void success(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('✅ $prefix$message');
    }
  }

  /// Log with custom emoji prefix (only in debug mode)
  static void custom(String emoji, String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('$emoji $prefix$message');
    }
  }
}
