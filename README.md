# data_repository

Repository layer for Flutter: typed HTTP requests, interceptors, response
caching, pagination and error normalisation behind one API.

[![pub package](https://img.shields.io/pub/v/data_repository.svg)](https://pub.dev/packages/data_repository)

## Features
see the live sample [here](https://wiseminds.github.io/data-repository/)


## Getting started

> Define your implementation of local and remote repositories.

The local repository manages caching and retrieving data localy, while the remote repository manages retrieving data from a remote source.
I would recommend using GetIt for this

```dart
   GetIt.I.registerSingleton<LocalRepository>(HiveRepository());
    GetIt.I.registerSingleton<RemoteRepository>(
        RemoteRepository((HttpApiProvider())));
```

> create an API service class. This is just a class where you define your API requests

```dart
class PostApi  {
  ApiRequest<Post, Post> create(CreatePostDto body) {
    return ApiRequest<Post, Post>(
        baseUrl: baseUrl,
        path: ApiUrls.department,
        method: ApiMethods.post,
        body: body.toJson,
        dataKey: 'data',
        error: ErrorDescription(),
        interceptors: [
        HeaderInterceptor({
                'Authorization': 'Bearer $token',
                "Content-Type": "application/json",
                "Accept": "application/json",
        }),
          JsonInterceptor<ErrorModel>(Models.factories),
          NetworkDurationInterceptor(),
        ]);
  }
}
```

> Create a resository class and extend the `DataRepository` class

Here you need to initialize your local and remote repository implementations.


```dart
class PostRepository extends DataRepository {
  final _api = PostApi();

  PostRepository()
      : super(GetIt.I<LocalRepository>(), GetIt.I<RemoteRepository>());

  Future<ApiResponse<Post, Post>> createPost(CreatePostDto body) async {
    return await handleRequest(_api.create(body));
  }

```

you can use your repository in you view model to fetch data and manage state based on the response.


```dart
 void createPost() async {
    emit(state.loading());

    final response = await _repository.createPost(CreatePostDto(
        title: state.title ?? '',
        content: state.content ?? '',
        image: state.image ?? ''));

    if (response.isSuccessful) {
      emit(PostCreated('Register success', state));
    } else {
      // print((response.error as ApiError).message);
      emit(ErrorState(response.error as ApiError, state));
    }
  }

```
### caching
in your repository, you can set `CacheDescription` to define if you want request to be cached.
you set the key, and the lifespan

```dart

  Future<ApiResponse<List<Post>, Post>> getPost() async {
    return await handleRequest(_api.getPost(),
        cache: CacheDescription('posts-list',
            lifeSpan: CacheDescription.oneMinute));
  }
```



### decoding responses

`JsonInterceptor` ships with the package. Give it a registry mapping each model
type to its factory, and the type parameter names the model an error body
decodes into:

```dart
class Models {
  static Map<Type, JsonFactory> factories = {
    Post: (json) => Post.fromJson(json),
    ErrorModel: (json) => ErrorModel.fromJson(json),
  };
}

// on the request:
JsonInterceptor<ErrorModel>(Models.factories)

// for a paginated endpoint (hasPagination: true):
JsonInterceptor<ErrorModel>(Models.factories,
    paginationFactory: PaginationModel.fromJson)
```

### error handling

`response.error` is the normalised `ApiError` you render. When the failure came
from an exception rather than an HTTP status, `response.cause` holds the
original throwable, so a custom exception thrown by an interceptor stays
recoverable:

```dart
if (!response.isSuccessful) {
  final cause = response.cause;
  if (cause is SessionExpiredException) return refresh(cause.refreshToken);
  showError((response.error as ApiError).message);
}
```

An interceptor that throws an `ApiError` carrying an HTTP status code has that
status surfaced on the response, so this works:

```dart
// in an interceptor's onRequest
if (tokenIsExpired) throw ApiError('Unauthorized', 401);

// at the call site
if (response.statusCode == 401) await refreshToken();
```

### logging

The package is silent unless you give it somewhere to write:

```dart
ApiConfig().logger = debugPrint;   // or your own logger
```

### connection reuse and testing

`HttpApiProvider` accepts an `http.Client`, which lets connections be reused
across requests and lets tests substitute a mock transport:

```dart
RemoteRepository(HttpApiProvider(client: MockClient((request) async {
  return http.Response('{"data": []}', 200);
})));
```

### interceptors
You can define interceptors to intercept request or response objects
Interceptors run before a request is fulfilled, and after response is gotten.
To create an interceptor, extend the `ApiInterceptor` class and override `onRequest` to 
intercept request and `onResponse` to intercept response and `onError` to intercept request error.

```dart

class NetworkDurationInterceptor extends ApiInterceptor {
  Map<String, int> timestamp = {};

  @override
  ApiResponse<ResponseType, InnerType> onResponse<ResponseType, InnerType>(
      ApiResponse<ResponseType, InnerType> response) {
    if (kDebugMode) {
      print(
          'NetworkDurationInterceptor ${response.statusCode}, ${response.request.requestId}, $timestamp ${timestamp[response.request.requestId]}');
    }

    var duration = DateTime.now().millisecondsSinceEpoch -
        (timestamp.remove(response.request.requestId) ?? 00);

    if (kDebugMode) {
      print('request completed in $duration milliseconds');
    }

    return response.copyWith(extra: {...?response.extra, 'duration': duration});
  }

  @override
  ApiRequest<ResponseType, InnerType> onRequest<ResponseType, InnerType>(
      ApiRequest<ResponseType, InnerType> request) {
    timestamp
        .addAll({request.requestId: DateTime.now().millisecondsSinceEpoch});
    return request; //.copyWith(: );
  }

  @override
  ApiResponse<ResponseType, InnerType> onError<ResponseType, InnerType>(
      ApiResponse<ResponseType, InnerType> response) {
    var duration = DateTime.now().millisecondsSinceEpoch -
        (timestamp.remove(response.request.requestId) ?? 00);

    if (kDebugMode) {
      print('request completed with error in $duration milliseconds');
    }

    return response.copyWith(extra: {...?response.extra, 'duration': duration});
  }
}

```

### Test Example

Pass a `MockClient` to `HttpApiProvider` to exercise the real request pipeline —
interceptors, URL building and decoding included — without a network:

```dart
void main() {
  test('decodes the response body', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/posts');
      return http.Response('{"data": [{"id": 1}]}', 200);
    });

    final repository = PostRepository(
      MapRepository(),
      RemoteRepository(HttpApiProvider(client: client)),
    );

    final response = await repository.getPosts();

    expect(response.isSuccessful, isTrue);
    expect(response.body, hasLength(1));
  });

  test('a failing interceptor keeps its status code', () async {
    final response = await remoteRepository.handleRequest(
      ApiRequest<Post, Post>(
        baseUrl: 'https://example.com',
        interceptors: [ExpiredTokenInterceptor()], // throws ApiError('...', 401)
      ),
    );

    expect(response.statusCode, 401);
  });
}
```

>> Check the example app for sample code
More examples comming soon