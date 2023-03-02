part of 'post_cubit.dart';

@immutable
class PostState extends Equatable {
  final bool isLoading;
  final int? requestDuration;
  final List<Post>? data;

  const PostState({this.isLoading = false, this.data, this.requestDuration});

  PostState loading() => copyWith(isLoading: true);

  PostState copyWith(
          {bool? isLoading, List<Post>? data, int? requestDuration}) =>
      PostState(
          isLoading: isLoading ?? false,
          data: data ?? this.data,
          requestDuration: requestDuration ?? this.requestDuration);

  @override
  List<Object?> get props => [isLoading, data, requestDuration];
}
