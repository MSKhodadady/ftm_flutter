import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:ftm_flutter/database.dart';
import 'package:ftm_flutter/files.dart';
import 'package:ftm_flutter/layouts/main_layout.dart';
import 'package:permission_handler/permission_handler.dart';

Directory getHomeDirectory() => Directory("/storage/emulated/0");

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    var deviceInfo = DeviceInfoPlugin();
    var androidInfo = await deviceInfo.androidInfo;

    if (androidInfo.version.sdkInt >= 30) {
      if (await Permission.manageExternalStorage.request().isGranted) {
        await initFilesDir();
      } else {
        exit(0);
      }
    } else {
      if (await Permission.storage.request().isGranted) {
        await initFilesDir();
      } else {
        exit(0);
      }
    }
  }

  await initDB();

  //: run app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.from(
          colorScheme: ColorScheme.light(
              primary: Colors.pink,
              onPrimary: Colors.white,
              secondary: Colors.amber,
              onSecondary: Colors.black,
              primaryContainer: Colors.pink.shade900)),
      home: const MainLayout(),
    );
  }
}
