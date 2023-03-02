import 'package:example/modules/post/views/post_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'dependency_injection.dart';

void main() async {
  await DependencyInjection.bootstrap();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Repository',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Examples')),
      body: ListView(children: [
        ListTile(
          title: const Text('Post list example'),
          subtitle: const Text('Fetching a list of posts'),
          onTap: () => Navigator.push(
              context, CupertinoPageRoute(builder: (c) => const PostScreen())),
        )
      ]),
    );
  }
}
