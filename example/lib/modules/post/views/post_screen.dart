import 'package:data_repository/cache/index.dart';
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const TextSpan(text: ' milliseconds')
                          ]),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  : const SizedBox();
            }),
            appBar: AppBar(title: const Text('Posts'), actions: [
              Builder(
                  builder: (context) => DropdownMenu<CacheDescription?>(
                          menuStyle: MenuStyle(
                              side: WidgetStateProperty.all(
                                  const BorderSide(color: Colors.white))),
                          textStyle: const TextStyle(color: Colors.white),
                          onSelected: context.read<PostCubit>().cacheUpdated,
                          initialSelection:
                              context.watch<PostCubit>().state.cache,
                          dropdownMenuEntries: [
                            const DropdownMenuEntry(
                                value: null, label: 'No cache'),
                            DropdownMenuEntry(
                                value: CacheDescription('posts-list-one-minute',
                                    lifeSpan: CacheDescription.oneMinute),
                                label: 'One minute cache'),
                            DropdownMenuEntry(
                                value: CacheDescription(
                                    'posts-list-ten-seconds',
                                    lifeSpan: CacheDescription.oneSecond * 10),
                                label: 'Ten seconds cache')
                          ])),
              Builder(builder: (context) {
                return IconButton(
                    onPressed: context.read<PostCubit>().getPosts,
                    icon: const Icon(Icons.refresh));
              }),
              const SizedBox(width: 50)
            ]),
            body: const PostList()));
  }
}
