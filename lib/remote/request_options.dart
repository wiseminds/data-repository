import 'cancellation_token.dart';
import 'retry_policy.dart';

/// Reports transfer progress. [total] is -1 when the length is unknown.
typedef ProgressCallback = void Function(int transferred, int total);

/// Per-call knobs that are not part of the request's description.
///
/// [ApiRequest] describes *what* to call and is typically built once by an API
/// class; these options describe *how* this particular call should behave, and
/// belong to the caller:
///
/// ```dart
/// repository.getPosts(options: RequestOptions(
///   cancelToken: _token,
///   retry: const RetryPolicy(maxAttempts: 5),
///   onReceiveProgress: (received, total) => setState(...),
/// ));
/// ```
class RequestOptions {
  /// Cancels this call when triggered.
  final CancellationToken? cancelToken;

  /// Overrides the repository's default retry behaviour for this call.
  final RetryPolicy? retry;

  /// Fires as the request body is uploaded.
  final ProgressCallback? onSendProgress;

  /// Fires as the response body is downloaded.
  final ProgressCallback? onReceiveProgress;

  /// Overrides the request's own timeout, in seconds.
  final int? timeout;

  /// Skips in-flight de-duplication for this call, forcing a fresh request
  /// even when an identical one is already running.
  final bool skipDeduplication;

  const RequestOptions({
    this.cancelToken,
    this.retry,
    this.onSendProgress,
    this.onReceiveProgress,
    this.timeout,
    this.skipDeduplication = false,
  });

  /// True when nothing here needs the transport to stream or watch the call.
  bool get isPlain =>
      cancelToken == null &&
      onSendProgress == null &&
      onReceiveProgress == null;
}
