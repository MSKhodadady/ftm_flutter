import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:ftm_flutter/io_manager.dart';
import 'package:ftm_flutter/layouts/main_layout.dart';
import 'package:ftm_flutter/pages/add_page.dart';
import 'package:ftm_flutter/pages/drivers_page.dart';
import 'package:ftm_flutter/pages/explore_page.dart';
import 'package:ftm_flutter/pages/select_file.dart';
import 'package:ftm_flutter/pages/trash_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
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
      initialRoute: '/explore',
      onGenerateRoute: (settings) {
        final currentPath = Uri.parse(settings.name!).path;

        final routesWithMainLayout = {
          '/explore': {
            'index': 0,
            'widget': const ExplorePage(),
          },
          '/add': {
            'index': 1,
            'widget': const AddPage(),
          },
          '/trash': {
            'index': 2,
            'widget': const TrashPage(),
          },
          '/drivers': {
            'index': 3,
            'widget': const DriversPage(),
          }
        };

        if (routesWithMainLayout.keys
            .toList()
            .any((element) => element == currentPath)) {
          return NoAnimationMaterialPageRoute(
            builder: (context) => MainLayoutWrapper(
              selectedIndex: routesWithMainLayout[currentPath]!['index'] as int,
              child: routesWithMainLayout[currentPath]!['widget'] as Widget,
            ),
          );
        }

        if (currentPath == '/select-files') {
          return MaterialPageRoute(
            builder: (context) => const SelectFile(),
          );
        }

        return MaterialPageRoute(
          builder: (context) => Container(),
        );
      },
    );
  }
}

class NoAnimationMaterialPageRoute<T> extends MaterialPageRoute<T> {
  NoAnimationMaterialPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    super.maintainState = true,
    super.fullscreenDialog = false,
  }) : super(
          builder: builder,
          settings: settings,
        );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}
