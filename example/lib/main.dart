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
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
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
