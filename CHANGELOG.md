## 1.0.0

### Breaking
* Renamed misspelled public API — no aliases are kept:
  * `ExceptionFormater` -> `ExceptionFormatter` (file `utils/exception_formater.dart` -> `exception_formatter.dart`)
  * `Jsonutils` -> `JsonUtils`
  * `ApiRequest.ovveride500Error` -> `override500Error`
  * `CacheManager.savToCache` -> `saveToCache`
* Removed `MyHttpOverrides`, which disabled TLS certificate validation for the whole process.
* Removed dead, fully commented-out files: `pagination_handler.dart`, `base_api_service.dart`,
  `dio_api_provider.dart`, `chopper_api_provider.dart`, and the no-op `String.normalizeUrl` extension.
* `mockito` moved from `dependencies` to `dev_dependencies`; it is no longer pulled into consumer apps.
* Failed transport now reports `ApiResponse.transportFailure` (0) instead of the invented `420`.
* `JsonUtils.convertToJson` throws `JsonSerializationException` instead of silently producing `"null"`.
* `CacheManager.getCachedData` is typed `Future<String?>` rather than `Future<dynamic>`.
* `ApiResponse.isSuccessful` now also requires `error == null`, so a 2xx response whose interceptor
  chain failed is not reported as successful.
* `ApiResponse.extra` is now `final`, matching its sibling fields.
* Removed the unused `retry` parameter from `handleRequest`, and the unused `pagination`
  parameter from `ApiRequest.copyWith`.
* The `dynamic.asInt` extension was removed in favour of the `Object.asInt` one; call sites on a
  nullable receiver now need `?.asInt`.

### Fixed
* Errors are no longer flattened on the exception path. `ApiResponse` gained `cause` and `stackTrace`,
  so a custom exception thrown by an interceptor is recoverable, and a thrown
  `ApiError('...', 401)` now surfaces as `statusCode: 401` instead of being overwritten.
* A throwing interceptor is no longer swallowed by `ApiResponse.resolve`; the failure is reported on
  the response instead of returning a half-resolved one.
* Multipart uploads could drop file parts: parts were added from an `async` callback passed to
  `Map.forEach`, which discards futures, so a part read from disk could resolve after `send()`.
* An unknown file extension no longer throws `FormatException`; parts fall back to
  `application/octet-stream`.
* URLs no longer get a trailing `?` when a request has no query parameters.
* An explicit `query` entry now takes precedence over one embedded in `path` (previously the reverse).
* `copyWith` can clear a field: `copyWith(body: null)` was a silent no-op on `ApiResponse` and `ApiRequest`.
* The empty-collection cache guard now works — it compared a type argument against a type and was
  always false, so empty lists were cached.
* Error classification uses `is` checks instead of matching `runtimeType.toString()`, which broke under
  release obfuscation and never matched subclasses.
* `MapRepository.getTime` no longer throws on a missing key.
* `JsonInterceptor.onError` decoded `dart:convert`'s top-level `json` object instead of the response body
  in its fallback path.

### Packaging
* Rewrote `pubspec.yaml` metadata: a fuller `description` (147 chars, within pub.dev's 60-180 range),
  plus `issue_tracker`, `documentation` and `topics` (networking, http, rest, cache, api) for
  discoverability. `homepage` now points at the live demo and `repository` at the source, instead of
  both duplicating the same URL. All four URLs verified reachable.
* Added `.pubignore`, shrinking the published archive from 296 KB to 36 KB by excluding the example's
  generated native scaffolding (android/ios/macos/windows/linux/web) and build artefacts.
* Fixed the dead demo link in the README (`data-repository.wiseminds.cc` no longer resolves); it now
  points at the live GitHub Pages deployment that CI publishes.

### Dependencies
* All direct and dev dependencies upgraded to their latest versions: `http` ^1.6.0, `mime` ^2.1.0,
  `path_provider` ^2.1.6, `http_parser` ^4.1.2, `mockito` ^5.8.1, `flutter_lints` ^6.0.0.
* **Raised the SDK floor to Dart `^3.10.3` / Flutter `>=3.38.4`.** This is required by the upgraded
  `path_provider` chain (`path_provider_foundation` 2.6.0); the other dependencies would allow Dart 3.4.
* Dropped the unused `test` dev dependency — the suite uses `flutter_test`, and `test` was the only
  constraint holding a package below its latest version.

### Added
* `JsonInterceptor` is now part of the package (`data_repository/remote/index.dart`) instead of something
  each consumer copy-pastes out of the example.
* `ApiConfig().logger` — an opt-in sink for the package's diagnostics. The package no longer prints to
  the console of an app that did not ask for it.
* `HttpApiProvider({http.Client? client})` for connection reuse and for testing with
  `package:http/testing.dart`.
* `ApiError` gained value equality; `ApiErrorStatus.hasHttpStatusCode` is available as an extension.
* Test suite grown from 1 test to 31, and CI now runs analysis, formatting and tests.

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
