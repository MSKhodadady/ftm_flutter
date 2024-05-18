import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:ftm_flutter/io_manager.dart';
import 'package:ftm_flutter/layouts/main_layout.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    //: TODO: device file info upgraded from 8 to 10,
    //: check no error for new version in android
    var deviceInfo = DeviceInfoPlugin();
    var androidInfo = await deviceInfo.androidInfo;

    if (androidInfo.version.sdkInt >= 30) {
      if (await Permission.manageExternalStorage.request().isGranted) {
        await initApp();
      } else {
        exit(0);
      }
    } else {
      if (await Permission.storage.request().isGranted) {
        await initApp();
      } else {
        exit(0);
      }
    }
  } else if (Platform.isLinux) {
    await windowManager.ensureInitialized();

    var windowOptions = const WindowOptions(
      size: Size(450, 670),
      center: true,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    await initApp();
  } else if (Platform.isWindows) {
    await initApp();
  }

  //: run app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget with WindowListener {
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
