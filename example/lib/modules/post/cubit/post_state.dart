part of 'post_cubit.dart';

@immutable
class PostState extends Equatable {
  final bool isLoading;
  final int? requestDuration;
  final List<Post>? data;
  final CacheDescription? cache;
  final String? error;
  final bool servedFromCache;

  const PostState({
    this.cache,
    this.isLoading = false,
    this.data,
    this.requestDuration,
    this.error,
    this.servedFromCache = false,
  });

  PostState loading() => copyWith(isLoading: true, error: null);

  PostState copyWith({
    bool? isLoading,
    List<Post>? data,
    int? requestDuration,
    CacheDescription? cache,
    String? error,
    bool? servedFromCache,
  }) =>
      PostState(
        isLoading: isLoading ?? false,
        data: data ?? this.data,
        cache: cache ?? this.cache,
        requestDuration: requestDuration ?? this.requestDuration,
        error: error,
        servedFromCache: servedFromCache ?? this.servedFromCache,
      );

  PostState updateCache(CacheDescription? cache) => PostState(
        data: data,
        cache: cache,
        requestDuration: requestDuration,
      );

  @override
  List<Object?> get props =>
      [isLoading, data, requestDuration, cache, error, servedFromCache];
}
