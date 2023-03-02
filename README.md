A data repository for flutter, manages both local and remote api access

## Features

## Getting started

Documentation coming soon

## Usage

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
          AuthInterceptor(),
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


>> Check the example app for sample code