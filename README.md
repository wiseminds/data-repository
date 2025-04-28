A data repository for flutter, manages both local and remote api access

## Features
see sample [here](https://data-repository.wiseminds.cc/#/)


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
          JsonInterceptor<ErrorModel>(DepartmentModels.factories),
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

```dart


void main() {
  group('HttpApiProvider Tests', () {
    late LocalRepository localRepository;
    late RemoteRepository remoteRepository;
    late TestRepository repository;

    setUp(() {
      remoteRepository = RemoteRepository(MockHttpApiProvider());
      localRepository = MapRepository();
      repository = TestRepository(localRepository, remoteRepository);
    });

    test('Test Exception Formater', () async {
      for (var type in ExceptionFormater.errorToObject.keys) {
        print('testing $type');
        var response = await repository.triggerError(type);
        expect(response.error, isA<ApiError>());
        expect(
            (response.error as ApiError).message,
            repository
                .formatErrorMessage(ExceptionFormater.errorToObject[type], '')
                .message);
         
      }
    });
 
  });
}

```
>> Check the example app for sample code
More examples comming soon