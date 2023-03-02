import 'package:data_repository/remote/index.dart';
import 'package:example/constants/api_urls.dart';
import 'package:example/data/api_client.dart';
import 'package:example/data/interceptors/json_interceptor.dart';
import 'package:example/models/error_model/error_model.dart';
import 'package:example/models/index.dart';
import 'package:example/models/post/post.dart';

class PostApi {
  // ApiRequest<Post, Post> create(CreatePostDto body) {
  //   return  ApiClient.baseRequest<Post, Post>().copyWith(
  //       path: ApiUrls.post,
  //       method: ApiMethods.post,
  //       body: body.toJson,
  //       dataKey: 'data',
  //       error: ErrorDescription(),
  //       interceptors: [
  //       HeaderInterceptor({
  //               'Authorization': 'Bearer $token',
  //               "Content-Type": "application/json",
  //               "Accept": "application/json",
  //       }),
  //         JsonInterceptor<ErrorModel>(DepartmentModels.factories),
  //         AuthInterceptor(),
  //       ]);
  // }

  ApiRequest<List<Post>, Post> getPost() {
    return ApiClient.baseRequest<List<Post>, Post>().copyWith(
        path: ApiUrls.posts,
        method: ApiMethods.get,
        dataKey: '',
        error: ErrorDescription(),
        interceptors: [
          HeaderInterceptor({
            // 'Authorization': 'Bearer $token',
            "Content-Type": "application/json",
            "Accept": "application/json",
          }),
          JsonInterceptor<ErrorModel>(Models.factories),
        ]);
  }
}
