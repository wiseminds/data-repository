import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/post_cubit.dart';
import 'post_list.dart';

class PostScreen extends StatelessWidget {
  const PostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PostCubit(),
      child: Scaffold(
          appBar: AppBar(
            title: const Text('Posts'),
            actions: [
              Builder(builder: (context) {
                return IconButton(
                    onPressed: context.read<PostCubit>().getPosts,
                    icon: const Icon(Icons.refresh));
              })
            ],
          ),
          body: const PostList()),
    );
  }
}
