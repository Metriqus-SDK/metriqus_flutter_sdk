import 'dart:async';
import 'dart:math';
import '../Metriqus.dart';

/// Exponential backoff utility class for retry operations
class Backoff {
  static int _operationCounter = 0;

  /// Execute operation with exponential backoff
  static Future<T?> execute<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 100),
    double multiplier = 2.0,
    Duration maxDelay = const Duration(seconds: 30),
    bool jitter = true,
  }) async {
    final operationId = ++_operationCounter;

    for (int retry = 0; retry <= maxRetries; retry++) {
      try {
        final result = await operation();
        return result;
      } catch (e) {
        if (retry == maxRetries) {
          // Last attempt failed
          Metriqus.errorLog(
              'Backoff operation $operationId failed on attempt ${retry + 1}: $e');
          rethrow;
        }

        // Calculate delay with exponential backoff
        try {
          final delay = _calculateDelay(
              retry, initialDelay, multiplier, maxDelay, jitter);
          Metriqus.verboseLog(
              'Backoff process waiting for ${delay.inMilliseconds}ms');
          await Future.delayed(delay);
        } catch (delayError) {
          Metriqus.errorLog('Backoff delay error: $delayError');
          // Continue without delay if delay calculation fails
        }
      }
    }

    return null;
  }

  /// Calculate delay with exponential backoff and optional jitter
  static Duration _calculateDelay(
    int attempt,
    Duration initialDelay,
    double multiplier,
    Duration maxDelay,
    bool jitter,
  ) {
    // Calculate exponential delay
    final exponentialDelay =
        initialDelay.inMilliseconds * pow(multiplier, attempt);

    // Apply max delay limit
    final delayMs = min(exponentialDelay, maxDelay.inMilliseconds.toDouble());

    if (!jitter) {
      return Duration(milliseconds: delayMs.round());
    }

    // Add jitter (±25% randomization)
    final random = Random();
    final jitterFactor = 0.75 + (random.nextDouble() * 0.5); // 0.75 to 1.25
    final finalDelay = delayMs * jitterFactor;

    return Duration(milliseconds: finalDelay.round());
  }

  /// Simple retry without exponential backoff
  static Future<T?> retry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt == maxRetries) {
          rethrow;
        }
        await Future.delayed(delay);
      }
    }
    return null;
  }

  /// Execute async operation with backoff (alias for execute)
  static Future<T?> doAsync<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 100),
    double multiplier = 2.0,
    Duration maxDelay = const Duration(seconds: 30),
    bool jitter = true,
  }) async {
    return execute<T>(
      operation,
      maxRetries: maxRetries,
      initialDelay: initialDelay,
      multiplier: multiplier,
      maxDelay: maxDelay,
      jitter: jitter,
    );
  }
}
