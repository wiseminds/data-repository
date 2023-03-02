import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:example/models/post/post.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../repository/post_repository.dart';

part 'post_state.dart';

class PostCubit extends Cubit<PostState> {
  PostCubit() : super(const PostState());

  final _repository = PostRepository();

  getPosts() async {
    emit(state.loading());

    final response = await _repository.getPost();
    emit(state.copyWith(
        isLoading: false, requestDuration: response.extra?.getKey('duration')));

    if (response.isSuccessful) {
      emit(state.copyWith(data: response.body));
    }
  }
}
