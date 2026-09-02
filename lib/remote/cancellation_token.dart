import 'dart:async';

/// Thrown into a request's future when its [CancellationToken] is cancelled.
class RequestCancelledException implements Exception {
  final String? reason;

  const RequestCancelledException([this.reason]);

  @override
  String toString() =>
      'RequestCancelledException${reason == null ? '' : ': $reason'}';
}

/// Cancels one or more in-flight requests.
///
/// Create a token, pass it via [RequestOptions], and cancel it when the work
/// is no longer needed — typically from a `dispose()`:
///
/// ```dart
/// final _token = CancellationToken();
///
/// @override
/// void dispose() {
///   _token.cancel('screen closed');
///   super.dispose();
/// }
/// ```
///
/// A cancelled request completes with
/// [ApiResponse.cancelled] as its status. Note that cancellation stops the
/// caller waiting on the response; it does not guarantee the underlying
/// socket is torn down, since `package:http` exposes no per-request abort.
class CancellationToken {
  final _completer = Completer<RequestCancelledException>();

  bool _isCancelled = false;
  RequestCancelledException? _cause;

  /// Whether [cancel] has been called.
  bool get isCancelled => _isCancelled;

  /// The exception this token was cancelled with, if any.
  RequestCancelledException? get cause => _cause;

  /// Completes when the token is cancelled. Never completes otherwise.
  Future<RequestCancelledException> get whenCancelled => _completer.future;

  /// Cancels every request holding this token. Calling it more than once has
  /// no further effect.
  void cancel([String? reason]) {
    if (_isCancelled) return;
    _isCancelled = true;
    _cause = RequestCancelledException(reason);
    _completer.complete(_cause);
  }

  /// Throws if this token has already been cancelled.
  void throwIfCancelled() {
    if (_isCancelled) throw _cause!;
  }
}
