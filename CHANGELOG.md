## 1.0.1

Fixes a runtime cast failure in `copyWith`. No API changes.

- `ApiRequest.copyWith(body: ...)` no longer throws
  `type '_Map<dynamic, dynamic>' is not a subtype of type 'Map<String, dynamic>?'`.
  The sentinel that distinguishes an omitted argument from an explicit null
  types `body` as `Object?`, so the analyzer stopped rejecting a
  `Map<dynamic, dynamic>` — a `Map.from` copy, a platform-channel map, a map
  literal with no context type — and the cast failed at runtime instead. Such a
  map is now re-keyed; a non-map argument raises an `ArgumentError` naming
  `body` rather than a bare cast error.
- `ApiResponse.copyWith(body: ...)` had the same latent failure, reachable from
  any interceptor doing `response.copyWith(body: decoded)`. A dynamic map is
  re-keyed when `BodyType` expects string keys; a genuine type mismatch is
  still reported.

## 1.0.0

A breaking release. Every rename and signature change is listed below with its
migration; most apps need only the mechanical renames in step 1.

### Migrating from 0.5.x

**1. Renames** — mechanical, no behaviour change:

| 0.5.x | 1.0.0 |
|---|---|
| `ExceptionFormater` | `ExceptionFormatter` |
| `utils/exception_formater.dart` | `utils/exception_formatter.dart` |
| `Jsonutils` | `JsonUtils` |
| `ApiRequest.ovveride500Error` | `ApiRequest.override500Error` |
| `CacheManager.savToCache` | `CacheManager.saveToCache` |

```bash
# from the project root. On Linux use `sed -i` instead of `sed -i ''`.
grep -rl 'ExceptionFormater\|Jsonutils\|ovveride500Error\|savToCache' lib test \
  | while IFS= read -r f; do
      sed -i '' \
        -e 's/ExceptionFormater/ExceptionFormatter/g' \
        -e 's/Jsonutils/JsonUtils/g' \
        -e 's/ovveride500Error/override500Error/g' \
        -e 's/savToCache/saveToCache/g' \
        -e 's/exception_formater/exception_formatter/g' "$f"
    done
```

**2. `build` and `resolve` are now `Future`s.** Only affects code calling them
directly; a custom `ApiProvider` is the usual case:

```dart
// before
request = request.build;
return ApiResponse(...).resolve;

// after
request = await request.build;
return await ApiResponse(...).resolve;
```

**3. `ApiProvider.send` takes an optional `RequestOptions`.** Custom providers
and hand-written fakes must widen their signature:

```dart
// before
Future<ApiResponse<R, I>> send<R, I>(ApiRequest<R, I> request) { ... }

// after
Future<ApiResponse<R, I>> send<R, I>(
  ApiRequest<R, I> request, [
  RequestOptions options = const RequestOptions(),
]) { ... }
```

Interceptors need no change: the hooks now return `FutureOr`, which a
synchronous implementation already satisfies.

**4. Transport failures report `0`, not `420`.** If you branched on the old
magic number, use the named constant — and note a thrown
`ApiError('...', 401)` now surfaces its own status instead of being
overwritten:

```dart
// before
if (response.statusCode == 420) showOffline();

// after
if (response.statusCode == ApiResponse.transportFailure) showOffline();
```

**5. `isSuccessful` now also requires `error == null`.** A 2xx response whose
interceptor chain threw is no longer reported as successful. If you relied on
the status alone, check `response.statusCode` directly.

**6. Unresolved `dataKey` paths return null instead of the whole body.** This
is the change most likely to look like a regression: a key that never existed
used to silently fall back to the root and appear to work. If a body starts
coming back null after upgrading, set `ApiConfig().logger` and look for
`did not resolve` — it names the failing segment.

**7. `ErrorDescription.key` defaults to the empty path** (the body itself)
rather than `'error'`. That matches what the old root-fallback produced for
most APIs. If your errors really are nested, say so explicitly:
`ErrorDescription(key: 'error')`.

**8. Smaller signature changes.** `handleRequest` lost its unused `retry`
parameter, `ApiRequest.copyWith` lost its unused `pagination` parameter, the
`Extra` class and `ApiRequest.extra` were removed (accepted but never used),
`CacheManager.getCachedData` is typed `Future<String?>`, and the `dynamic.asInt`
extension was dropped in favour of the `Object` one — a nullable receiver now
needs `?.asInt`.

**9. SDK floor.** Dart `^3.10.3` / Flutter `>=3.38.4`, required by the upgraded
`path_provider` chain.

### Breaking

* Renamed misspelled public API, with no aliases kept — see migration step 1.
* `ApiRequest.build` and `ApiResponse.resolve` are now `Future`s, following the
  async interceptor hooks.
* `ApiProvider.send` takes an optional `RequestOptions`, and gained `close()`.
* `ApiInterceptor` hooks return `FutureOr` rather than a plain value. Existing
  synchronous interceptors satisfy this unchanged.
* Failed transport reports `ApiResponse.transportFailure` (`0`) instead of the
  invented `420`, and a cancelled call reports `ApiResponse.cancelled` (`-1`).
* `ApiResponse.isSuccessful` additionally requires `error == null`.
* A `dataKey` / `paginationKey` / error key that does not resolve now yields
  null and logs the failing segment, instead of silently returning the whole
  body.
* `ErrorDescription.key` defaults to the empty path rather than `'error'`.
* `JsonUtils.convertToJson` throws `JsonSerializationException` instead of
  silently producing the string `"null"`.
* Removed `MyHttpOverrides`, which disabled TLS certificate validation for the
  whole process.
* Removed the `Extra` class and `ApiRequest.extra`; removed the unused `retry`
  parameter from `handleRequest` and `pagination` from `ApiRequest.copyWith`.
* Removed the `dynamic.asInt` extension in favour of the `Object` one.
* Removed dead, fully commented-out files: `pagination_handler.dart`,
  `base_api_service.dart`, `dio_api_provider.dart`, `chopper_api_provider.dart`,
  and the no-op `String.normalizeUrl` extension.
* `CacheManager.getCachedData` is typed `Future<String?>`; `ApiResponse.extra`
  is now `final`.
* `mockito` moved from `dependencies` to `dev_dependencies`; it is no longer
  pulled into consumer apps.

### Deprecated

* **`ApiRequest.nestedKey`.** It existed only because `dataKey` could resolve a
  single key, so an envelope needed a second anchor. With both now dotted paths:

  ```dart
  // before
  nestedKey: 'result', dataKey: 'data'

  // after
  dataKey: 'result.data', paginationKey: 'result'
  ```

  It continues to work unchanged — including scoping `dataKey` relative to it —
  and will be removed in a future release.

### Added

* **Async interceptors.** Every `ApiInterceptor` hook returns `FutureOr`, so an
  interceptor can await — refresh a token, read from secure storage — before the
  request goes out.
* **`RetryPolicy`** with exponential backoff and jitter, configurable app-wide
  on `RemoteRepository`, per request via `ApiRequest.retryPolicy`, or per call
  via `RequestOptions.retry`. Retries transport failures, timeouts, 408, 429 and
  5xx, and only for idempotent methods. The request is rebuilt on each attempt,
  so a token refreshed in `onError` is picked up by the replay.
* **`CancellationToken`** and `RequestOptions.cancelToken`. A cancelled call
  returns `ApiResponse.cancelled` with `isCancelled == true` rather than an
  error the UI must filter out.
* **`FileLocalRepository`**, a persistent `LocalRepository` built on
  `CacheManager`, so caching works without writing a storage adapter first.
* **In-flight de-duplication.** Identical concurrent GETs share one network
  call. On by default; disable per call with `RequestOptions.skipDeduplication`
  or globally on `RemoteRepository`.
* **`LoggingInterceptor`**, emitting through `ApiConfig().logger`, redacting
  `Authorization`, `Cookie` and `X-Api-Key`, and truncating long bodies.
* **Upload and download progress** via `RequestOptions.onSendProgress` and
  `onReceiveProgress`.
* **`RequestOptions`**, carrying per-call cancellation, retry, progress and
  timeout so none of these becomes another parameter on `handleRequest`.
* **Dotted paths** for `dataKey`, `paginationKey` and `ErrorDescription.key`:
  `'response.payload.items'`, list indices (`'data.pages[0].items'`) and
  backslash-escaped literal dots. A single key with no dots behaves exactly as
  before. `JsonPath` is exported for direct use.
* **`paginationKey`**, a dotted path to the object carrying the pagination
  fields, defaulting to the root.
* **`JsonInterceptor` is now part of the package**, instead of something each
  consumer copy-pastes out of the example.
* **`ApiConfig().logger`** — an opt-in sink for diagnostics. The package no
  longer prints to the console of an app that did not ask for it.
* **`HttpApiProvider({http.Client? client})`** for connection reuse and for
  testing with `package:http/testing.dart`.
* `ApiResponse.cause` and `stackTrace`; `ApiError` value equality; and
  `ApiErrorStatus.hasHttpStatusCode` as an extension.

### Fixed

* Errors are no longer flattened on the exception path. A custom exception
  thrown by an interceptor is recoverable via `ApiResponse.cause`, and a thrown
  `ApiError('...', 401)` surfaces as `statusCode: 401` instead of being
  overwritten by a hardcoded `420`.
* A throwing interceptor is no longer swallowed by `ApiResponse.resolve`; the
  failure is reported on the response instead of returning a half-resolved one.
* Multipart uploads could drop file parts: parts were added from an `async`
  callback passed to `Map.forEach`, which discards futures, so a part read from
  disk could resolve after the request was sent.
* An unknown file extension no longer throws `FormatException`; parts fall back
  to `application/octet-stream`.
* URLs no longer gain a trailing `?` when a request has no query parameters.
* An explicit `query` entry now takes precedence over one embedded in `path`
  (previously the reverse).
* `copyWith` can clear a field: `copyWith(body: null)` was a silent no-op on
  both `ApiResponse` and `ApiRequest`.
* The empty-collection cache guard now works — it compared a type argument
  against a type and was always false, so empty lists were cached.
* Error classification uses `is` checks instead of matching
  `runtimeType.toString()`, which stopped matching under release obfuscation and
  never matched subclasses.
* `CacheManager` no longer derives filenames from the last path segment, which
  collided distinct keys such as `posts/1` and `comments/1` onto one file.
* `MapRepository.getTime` no longer throws on a missing key.
* `JsonInterceptor.onError` decoded `dart:convert`'s top-level `json` object
  instead of the response body in its fallback path.

### Changed

* `HttpApiProvider` issues requests through `Client.send`, which is what enables
  streaming progress and cancellation.

### Packaging

* Rewrote `pubspec.yaml` metadata: a fuller `description` (147 chars, within
  pub.dev's 60-180 range), plus `issue_tracker`, `documentation` and `topics`.
  `homepage` points at the live demo and `repository` at the source, instead of
  both duplicating the same URL.
* Added `.pubignore`, shrinking the published archive from 296 KB to 36 KB by
  excluding the example's generated native scaffolding and build artefacts.
* Fixed the dead demo link in the README (`data-repository.wiseminds.cc` no
  longer resolves); it now points at the GitHub Pages deployment CI publishes.
* Test suite grown from 1 test to 84; CI now runs analysis, formatting and tests.

### Dependencies

* All direct and dev dependencies upgraded to latest: `http` ^1.6.0,
  `mime` ^2.1.0, `path_provider` ^2.1.6, `http_parser` ^4.1.2, `mockito` ^5.8.1,
  `flutter_lints` ^6.0.0.
* **SDK floor raised to Dart `^3.10.3` / Flutter `>=3.38.4`**, required by the
  upgraded `path_provider` chain (`path_provider_foundation` 2.6.0); the other
  dependencies alone would allow Dart 3.4.
* Dropped the unused `test` dev dependency — the suite uses `flutter_test`.

## 0.5.1
* added client exception support
## 0.5.0
* filter out network error correctly
* Updated packages
* Updated constraints
* Added sample test to readme
## 0.4.5
* Updated error messaage
## 0.4.4
* Fixed body payload for patch and delete methods in the default http provider
## 0.4.3
* Fixed double slash in path segment
## 0.4.1
* Fixed JSONUtils null issue
## 0.4.1
* Fixed invalid cache data
## 0.4.0
* Removed chunkCount
* Added getter to check has next page and previous page
## 0.3.0
* Upgraded packages
## 0.2.4
* Added support for patch on http client
## 0.2.3
* Added mimetype for file upload
## 0.2.2
* Updated exception filter
## 0.2.1
* Fixed analysis issues
## 0.2.0
* Added id request to identify unique request
* Updated README
* Added example app
## 0.1.10
* updated suport for bytes upload
## 0.1.9
* Added suport for bytes upload
## 0.1.8
* Removed api provider from base api service
## 0.1.7
* Fixed cache algorithm
## 0.1.6
* Fixed query parameters not added to Uri
## 0.1.5
* Fixed query parameters not added to Uri
## 0.1.4
* Fixed cache not resolving data
## 0.1.3
* Fixed url encoding issue
* Fixed multi-part request builder
## 0.1.2
* updated data repository, added api provider to remote repository
## 0.1.1
* updated data repository
## 0.1.0
* added request to data repository parameters
## 0.0.8
* Updated Api URI parser
## 0.0.7
* optimized api provider
## 0.0.6
* optimized api provider
## 0.0.5
* updated pagination
## 0.0.4
* Added pagination to request
## 0.0.3
* Added header interceptor
## 0.0.2
* Refactored project
## 0.0.1
* Finished basic setup
