import 'package:example/modules/post/cubit/post_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PostList extends StatefulWidget {
  const PostList({super.key});

  @override
  State<PostList> createState() => _PostListState();
}

class _PostListState extends State<PostList> {
  @override
  void initState() {
    super.initState();
    context.read<PostCubit>().getPosts();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostCubit, PostState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                )),
          );
        }
        if ((state.data ?? []).isEmpty) {
          return const Center(child: Text('No posts found'));
        }
        return ListView.builder(
            itemCount: state.data?.length,
            itemBuilder: (c, i) {
              var item = state.data![i];
              return ListTile(
                  leading: Text('${item.id}'),
                  title: Text(item.title),
                  subtitle: Text(item.body ?? ''));
            });
      },
    );
  }
}
