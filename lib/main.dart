import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ftm_flutter/files.dart';
import 'package:ftm_flutter/layouts/main_layout.dart';
import 'package:permission_handler/permission_handler.dart';

Directory getHomeDirectory() => Directory("/storage/emulated/0");

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //: files dir
  if (await Permission.storage.isGranted) {
    await initFilesDir();
  } else {
    if (await Permission.storage.request().isGranted) {
      await initFilesDir();
    } else {
      // TODO show a message for not having storage permission
      exit(0);
    }
  }
  //: run app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.from(
          colorScheme: ColorScheme.light(
              primary: Colors.pink,
              secondary: Colors.amber,
              primaryContainer: Colors
                  .pink.shade900 /*primaryVariant: Colors.pink.shade900*/)),
      home: const MainLayout(),
    );
  }
}
