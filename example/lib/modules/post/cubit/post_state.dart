part of 'post_cubit.dart';

@immutable
class PostState extends Equatable {
  final bool isLoading;
  final int? requestDuration;
  final List<Post>? data;
  final CacheDescription? cache;

  const PostState(
      {this.cache, this.isLoading = false, this.data, this.requestDuration});

  PostState loading() => copyWith(isLoading: true);

  PostState copyWith(
          {bool? isLoading,
          List<Post>? data,
          int? requestDuration,
          CacheDescription? cache}) =>
      PostState(
          isLoading: isLoading ?? false,
          data: data ?? this.data,
          cache: cache ?? this.cache,
          requestDuration: requestDuration ?? this.requestDuration);

  PostState updateCache(CacheDescription? cache) =>
      PostState(data: data, cache: cache, requestDuration: requestDuration);

  @override
  List<Object?> get props => [isLoading, data, requestDuration, cache];
}
