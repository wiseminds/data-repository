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
          bottomNavigationBar: Builder(builder: (context) {
            return context.watch<PostCubit>().state.requestDuration != null
                ? Material(
                    color: Theme.of(context).primaryColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: 'Request completed in'),
                          TextSpan(
                              text:
                                  ' ${context.watch<PostCubit>().state.requestDuration} ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const TextSpan(text: ' milliseconds')
                        ]),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                : const SizedBox();
          }),
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
