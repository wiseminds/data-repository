import 'package:data_repository/data_repository.dart';
import 'package:example/models/post/post.dart';

import '../data/post_api.dart';

/// Depends only on abstractions, all supplied by the caller.
///
/// Nothing here knows whether the cache is a file, Hive or a plain map, nor
/// whether requests travel over http or a fake. That is what makes this class
/// constructible in a test with two lines and no locator:
///
/// ```dart
/// final repository = PostRepository(
///   MapRepository(),
///   RemoteRepository(HttpApiProvider(client: MockClient(...))),
///   PostApi(baseUrl: 'https://example.com'),
/// );
/// ```
class PostRepository extends DataRepository {
  final PostApi _api;

  PostRepository(
    super.localRepository,
    super.remoteRepository,
    this._api,
  );

  /// [options] lets the caller cancel the load, watch progress or override
  /// retries without this method growing a parameter for each.
  Future<ApiResponse<List<Post>, Post>> getPosts({
    CacheDescription? cache,
    RequestOptions options = const RequestOptions(),
  }) =>
      handleRequest(_api.getPosts(), cache: cache, options: options);

  Future<ApiResponse<Post, Post>> getPost(
    int id, {
    RequestOptions options = const RequestOptions(),
  }) =>
      handleRequest(
        _api.getPost(id),
        cache: CacheDescription('post-$id',
            lifeSpan: CacheDescription.oneMinute * 5),
        options: options,
      );
}
