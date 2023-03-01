// typedef JsonFactory<T> = T Function(Map<String, dynamic> json);

import 'package:data_repository/data_repository.dart' hide Pagination;
import 'package:example/models/pagination/pagination.dart';

import 'error_model/error_model.dart';
import 'post/post.dart';

class Models {
  static Map<Type, JsonFactory> factories = {
    ErrorModel: (json) => ErrorModel.fromJson(json),
    Post: (json) => Post.fromJson(json),
    Pagination: (json) => Pagination.fromJson(json),
  };
}
