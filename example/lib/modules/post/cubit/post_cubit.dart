import 'package:data_repository/data_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:example/models/post/post.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../repository/post_repository.dart';

part 'post_state.dart';

class PostCubit extends Cubit<PostState> {
  final PostRepository _repository;

  /// The repository is injected rather than constructed here, so a test can
  /// drive this cubit against a fake transport.
  PostCubit(this._repository) : super(const PostState());

  /// Cancels whatever is still in flight when this cubit is disposed.
  CancellationToken _token = CancellationToken();

  void cacheUpdated(CacheDescription? value) {
    emit(state.updateCache(value));
    Future.delayed(Duration.zero, getPosts);
  }

  Future<void> getPosts() async {
    emit(state.loading());

    final startedAt = DateTime.now();
    final response = await _repository.getPosts(
      cache: state.cache,
      options: RequestOptions(cancelToken: _token),
    );

    // A cancelled load is not a failure worth showing anyone.
    if (response.isCancelled) return;

    emit(state.copyWith(
      isLoading: false,
      requestDuration: DateTime.now().difference(startedAt).inMilliseconds,
      servedFromCache: response.statusCode == ApiResponse.cacheHit,
    ));

    if (response.isSuccessful) {
      emit(state.copyWith(data: response.body));
    } else {
      emit(state.copyWith(error: (response.error as ApiError?)?.message));
    }
  }

  @override
  Future<void> close() {
    _token.cancel('post list closed');
    return super.close();
  }

  /// Discards the token so a later load is not cancelled by an earlier close.
  void restart() => _token = CancellationToken();
}
