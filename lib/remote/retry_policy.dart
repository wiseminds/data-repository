import 'dart:math';

import 'api_methods.dart';
import 'api_response.dart';

/// Decides whether a failed response is worth another attempt.
typedef RetryPredicate = bool Function(ApiResponse response, int attempt);

/// Controls automatic re-attempts of a failed request.
///
/// The request is rebuilt on every attempt, so its `onRequest` interceptors run
/// again — that is what lets an interceptor refresh an expired token in
/// `onError` and have the replay pick up the new one.
class RetryPolicy {
  /// Total attempts including the first. `1` disables retrying.
  final int maxAttempts;

  /// Delay before the second attempt; grows by [backoffFactor] thereafter.
  final Duration initialDelay;

  /// Multiplier applied to the delay after each failed attempt.
  final double backoffFactor;

  /// Upper bound on any single delay.
  final Duration maxDelay;

  /// Fraction of random jitter (0..1) applied to each delay, so that clients
  /// failing together do not retry in lockstep.
  final double jitter;

  /// Whether a given failure should be retried.
  final RetryPredicate retryIf;

  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 300),
    this.backoffFactor = 2.0,
    this.maxDelay = const Duration(seconds: 10),
    this.jitter = 0.2,
    this.retryIf = retryTransientFailures,
  });

  /// A policy that never retries.
  static const none = RetryPolicy(maxAttempts: 1);

  /// Default predicate: retry transport failures, timeouts and 5xx responses,
  /// but only for methods that are safe to repeat.
  ///
  /// POST and PATCH are excluded because replaying them can duplicate work.
  /// Pass a custom [retryIf] to opt them in.
  static bool retryTransientFailures(ApiResponse response, int attempt) {
    if (!_isIdempotent(response.request.method)) return false;
    final status = response.statusCode;
    return status == ApiResponse.transportFailure ||
        status == 408 ||
        status == 429 ||
        (status >= 500 && status <= 599);
  }

  static bool _isIdempotent(String? method) =>
      method == null ||
      method == ApiMethods.get ||
      method == ApiMethods.head ||
      method == ApiMethods.put ||
      method == ApiMethods.delete;

  /// Delay to wait before attempt number [attempt] (1-based; the delay before
  /// the second attempt is `delayFor(1)`).
  Duration delayFor(int attempt) {
    final scaled =
        initialDelay.inMilliseconds * pow(backoffFactor, attempt - 1);
    final capped = min(scaled.toDouble(), maxDelay.inMilliseconds.toDouble());
    if (jitter <= 0) return Duration(milliseconds: capped.round());
    // Deterministic-free jitter is fine here; this only spreads load.
    final spread = capped * jitter;
    final value = capped - spread + Random().nextDouble() * spread * 2;
    return Duration(milliseconds: max(0, value).round());
  }
}
