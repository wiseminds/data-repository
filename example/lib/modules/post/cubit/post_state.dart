part of 'post_cubit.dart';

@immutable
class PostState extends Equatable {
  final bool isLoading;
  final List<Post>? data;

  const PostState({this.isLoading = false, this.data});

  PostState loading() => copyWith(isLoading: true);

  PostState copyWith({bool? isLoading, List<Post>? data}) =>
      PostState(isLoading: isLoading ?? false, data: data ?? this.data);

  @override
  List<Object?> get props => [isLoading, data];
}
