import 'package:data_repository/data_repository.dart';
import 'package:example/constants/api_urls.dart';
import 'package:example/models/error_model/error_model.dart';
import 'package:example/models/index.dart';
import 'package:example/models/post/post.dart';

/// Describes *what* to call. Nothing here performs I/O, so an API class is
/// trivially unit-testable and can be reused against any [ApiProvider].
class PostApi {
  final String baseUrl;

  PostApi({required this.baseUrl});

  ApiRequest<ResponseType, InnerType> _base<ResponseType, InnerType>() =>
      ApiRequest<ResponseType, InnerType>(
        baseUrl: baseUrl,
        error: ErrorDescription(),
        interceptors: [
          HeaderInterceptor(const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          }),
          // Emits through ApiConfig().logger; inert when none is set.
          LoggingInterceptor(),
          JsonInterceptor<ErrorModel>(Models.factories),
        ],
      );

  ApiRequest<List<Post>, Post> getPosts() =>
      _base<List<Post>, Post>().copyWith(path: ApiUrls.posts);

  ApiRequest<Post, Post> getPost(int id) =>
      _base<Post, Post>().copyWith(path: '${ApiUrls.posts}/$id');
}
