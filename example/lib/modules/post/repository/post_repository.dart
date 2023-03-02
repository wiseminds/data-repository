import 'package:data_repository/data_repository.dart';
import 'package:example/models/post/post.dart';
import 'package:get_it/get_it.dart';

import '../data/post_api.dart';

class PostRepository extends DataRepository {
  PostRepository()
      : super(GetIt.I<LocalRepository>(), GetIt.I<RemoteRepository>());

  final _api = PostApi();

  Future<ApiResponse<List<Post>, Post>> getPost() async {
    return await handleRequest(_api.getPost());
  }
}
