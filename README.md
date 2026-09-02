# data_repository

A repository layer for Flutter that unifies typed HTTP requests, interceptors,
response caching, pagination and error normalisation behind one API.

[![pub package](https://img.shields.io/pub/v/data_repository.svg)](https://pub.dev/packages/data_repository)

See the live sample [here](https://wiseminds.github.io/data-repository/).

```dart
final response = await repository.getPosts();

if (response.isSuccessful) {
  render(response.body!);            // already decoded into List<Post>
} else {
  showError((response.error as ApiError).message);
}
```

---

## Built on dependency inversion

Every moving part is an interface you supply, and the layer above it never
learns which implementation it got. That is the whole design:

| Abstraction | What it decides | Ships with | Swap it for |
|---|---|---|---|
| `LocalRepository` | where cached data lives | `FileLocalRepository`, `MapRepository` | Hive, Isar, shared_preferences |
| `ApiProvider` | how requests travel | `HttpApiProvider` | Dio, gRPC gateway, an in-memory fake |
| `ApiInterceptor` | what happens per request | `Header`, `Json`, `Logging` | auth, tracing, signing |

Your repository depends on the two interfaces, and on nothing else:

```dart
class PostRepository extends DataRepository {
  final PostApi _api;
  PostRepository(super.localRepository, super.remoteRepository, this._api);

  Future<ApiResponse<List<Post>, Post>> getPosts() =>
      handleRequest(_api.getPosts());
}
```

Concrete types are named in exactly one place — the composition root:

```dart
locator.registerSingleton<LocalRepository>(FileLocalRepository());
locator.registerSingleton<ApiProvider>(HttpApiProvider());
locator.registerSingleton<RemoteRepository>(
  RemoteRepository(locator<ApiProvider>(), 'Something went wrong'),
);
locator.registerLazySingleton(
  () => PostRepository(locator(), locator(), PostApi(baseUrl: env.baseUrl)),
);
```

Because nothing reaches into the locator, the same repository is constructible
in a test with no framework at all:

```dart
final repository = PostRepository(
  MapRepository(),                                  // cache -> memory
  RemoteRepository(HttpApiProvider(                 // transport -> canned
    client: MockClient((_) async => http.Response('[{"id":1}]', 200)),
  )),
  PostApi(baseUrl: 'https://example.com'),
);
```

GetIt is used in the example for convenience — the package has no opinion and
no dependency on it. Constructor parameters are the only contract.

---

## Getting started

Add the dependency, then define an API class describing *what* to call. It
performs no I/O, so it stays trivially testable:

```dart
class PostApi {
  final String baseUrl;
  PostApi({required this.baseUrl});

  ApiRequest<List<Post>, Post> getPosts() => ApiRequest<List<Post>, Post>(
        baseUrl: baseUrl,
        path: 'posts',
        error: ErrorDescription(),
        interceptors: [
          HeaderInterceptor(const {'Accept': 'application/json'}),
          JsonInterceptor<ErrorModel>(Models.factories),
        ],
      );
}
```

The two type parameters are the response type and its element type: for a list
endpoint that is `<List<Post>, Post>`; for a single object, `<Post, Post>`.

---

## Decoding responses

`JsonInterceptor` turns bodies into typed models. Give it a registry mapping a
type to its factory; the type parameter names the model an *error* body
decodes into:

```dart
class Models {
  static Map<Type, JsonFactory> factories = {
    Post: (json) => Post.fromJson(json),
    ErrorModel: (json) => ErrorModel.fromJson(json),
  };
}

JsonInterceptor<ErrorModel>(Models.factories)

// paginated endpoints (hasPagination: true)
JsonInterceptor<ErrorModel>(Models.factories,
    paginationFactory: PaginationModel.fromJson)
```

Use `dataKey` when the payload is nested (`{"data": [...]}` → `dataKey: 'data'`)
and `nestedKey` to unwrap an outer envelope first.

---

## Caching

Pass a `CacheDescription` and the response is served from the local repository
until it expires:

```dart
Future<ApiResponse<List<Post>, Post>> getPosts() => handleRequest(
      _api.getPosts(),
      cache: CacheDescription('posts-list', lifeSpan: CacheDescription.oneMinute),
    );
```

`overrideTime` ignores expiry, `invalidateCache` forces a refetch, `ignoreSave`
reads without writing, and `retryWithCache: true` falls back to stale data when
the network fails. A cache hit reports `ApiResponse.cacheHit`.

`FileLocalRepository` persists to disk with no extra dependency. Swap in
`MapRepository` for tests, or adapt any store you like:

```dart
class HiveRepository implements LocalRepository { /* ... */ }
```

---

## Retries and backoff

Transient failures are re-attempted with exponential backoff and jitter. The
request is rebuilt on every attempt, so `onRequest` interceptors run again:

```dart
RemoteRepository(provider, 'Something went wrong',
    const RetryPolicy(maxAttempts: 3));           // app-wide default

repository.getPosts(options: const RequestOptions(  // or per call
  retry: RetryPolicy(maxAttempts: 5, initialDelay: Duration(seconds: 1)),
));
```

By default only transport failures, timeouts, 408, 429 and 5xx are retried, and
only for idempotent methods — replaying a POST can duplicate work. Opt in with
your own predicate:

```dart
RetryPolicy(retryIf: (response, attempt) => response.statusCode >= 500)
```

---

## Async interceptors and token refresh

Every hook returns `FutureOr`, so an interceptor can be synchronous *or* await.
That is what makes an in-band token refresh possible:

```dart
class AuthInterceptor extends ApiInterceptor {
  @override
  Future<ApiRequest<R, I>> onRequest<R, I>(ApiRequest<R, I> request) async {
    final token = await _store.readToken();          // await freely
    return request.copyWith(headers: {'Authorization': 'Bearer $token'});
  }

  @override
  Future<ApiResponse<R, I>> onError<R, I>(ApiResponse<R, I> response) async {
    if (response.statusCode == 401) await _store.refresh();
    return response;
  }
}
```

Combined with a retry policy that treats 401 as retryable, the replayed attempt
picks up the refreshed token automatically:

```dart
options: const RequestOptions(
  retry: RetryPolicy(maxAttempts: 2, retryIf: _retryUnauthorized),
)
```

---

## Cancellation

```dart
final _token = CancellationToken();

Future<void> load() => repository.getPosts(
      options: RequestOptions(cancelToken: _token),
    );

@override
void dispose() {
  _token.cancel('screen closed');
  super.dispose();
}
```

A cancelled call returns a response with `isCancelled == true` and
`ApiResponse.cancelled` as its status, rather than an error you would have to
filter out of your UI. Cancellation stops the caller waiting; it does not
guarantee the socket is torn down, since `package:http` exposes no per-request
abort.

---

## Progress

```dart
repository.upload(file, options: RequestOptions(
  onSendProgress: (sent, total) => setState(() => _progress = sent / total),
  onReceiveProgress: (received, total) { /* ... */ },
));
```

`total` is `-1` when the length is unknown.

---

## Request de-duplication

Identical GETs issued while one is already in flight share a single network
call — two widgets asking for the same data on the same frame cost one request.
It is on by default; disable it per call with
`RequestOptions(skipDeduplication: true)` or globally via the `RemoteRepository`
constructor.

---

## Error handling

`response.error` is the normalised `ApiError` you render. When the failure came
from an exception, `response.cause` holds the original throwable, so a custom
exception stays recoverable:

```dart
if (!response.isSuccessful) {
  final cause = response.cause;
  if (cause is SessionExpiredException) return refresh(cause.refreshToken);
  showError((response.error as ApiError).message);
}
```

An interceptor throwing an `ApiError` with an HTTP status has that status
surfaced on the response:

```dart
if (tokenIsExpired) throw ApiError('Unauthorized', 401);   // in onRequest
// ...
if (response.statusCode == 401) await refreshToken();      // at the call site
```

---

## Logging

The package writes nothing unless you give it somewhere to write:

```dart
ApiConfig().logger = debugPrint;
```

Add `LoggingInterceptor()` to a request chain for per-request detail. It
redacts `Authorization`, `Cookie` and `X-Api-Key` by default and truncates long
bodies:

```
--> GET https://api.example.com/posts
    headers: {Authorization: ***, Accept: application/json}
<-- 200 GET https://api.example.com/posts (142ms)
```

---

## Custom interceptors

Extend `ApiInterceptor` and override the hooks you need — each defaults to a
pass-through:

```dart
class TracingInterceptor extends ApiInterceptor {
  @override
  ApiRequest<R, I> onRequest<R, I>(ApiRequest<R, I> request) =>
      request.copyWith(headers: {'X-Trace-Id': newTraceId()});
}
```

`onRequest` runs before the call, `onResponse` after a 2xx, `onError`
otherwise. Interceptors passed to `copyWith` are *appended* to the chain, so a
per-endpoint interceptor never discards the shared ones.

---

## Testing

`HttpApiProvider` takes an `http.Client`, so the whole pipeline — URL building,
headers, interceptors, decoding — runs against a canned transport:

```dart
test('decodes the response body', () async {
  final client = MockClient((request) async {
    expect(request.url.path, '/posts');
    return http.Response('{"data": [{"id": 1}]}', 200);
  });

  final repository = PostRepository(
    MapRepository(),
    RemoteRepository(HttpApiProvider(client: client)),
    PostApi(baseUrl: 'https://example.com'),
  );

  final response = await repository.getPosts();

  expect(response.isSuccessful, isTrue);
  expect(response.body, hasLength(1));
});
```

For a fake with no HTTP at all, implement `ApiProvider` directly and inject it.

---

## API surface

| Type | Role |
|---|---|
| `DataRepository` | base class you extend; decides cache vs network |
| `RemoteRepository` | retries, de-duplication, cancellation, error normalisation |
| `ApiProvider` | the transport seam |
| `ApiRequest` / `ApiResponse` | the description of a call and its result |
| `RequestOptions` | per-call cancellation, retry, progress, timeout |
| `RetryPolicy` / `CancellationToken` | retry behaviour and cancellation |
| `LocalRepository` | the persistence seam |
| `ApiInterceptor` | the per-request hook |
| `ApiConfig` | logger and default error message |

Check the [example app](example/) for the full wiring.
