import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:ftm_flutter/controllers/selected_files.dart';
import 'package:ftm_flutter/layouts/main_layout.dart';
import 'package:ftm_flutter/views/add/model.dart';
import 'package:ftm_flutter/views/add/view.dart';
import 'package:ftm_flutter/pages/drivers_page.dart';
import 'package:ftm_flutter/views/select/model.dart';
import 'package:ftm_flutter/views/select/view.dart';
import 'package:ftm_flutter/pages/trash_page.dart';
import 'package:ftm_flutter/repos/driver.dart';
import 'package:ftm_flutter/services/app_conf.dart';
import 'package:ftm_flutter/services/database.dart';
import 'package:ftm_flutter/views/explore/model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:ftm_flutter/views/explore/view.dart';
import 'package:ftm_flutter/services/driver.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    //: FIXME: move these out

    //: check no error for new version in android
    var deviceInfo = DeviceInfoPlugin();
    var androidInfo = await deviceInfo.androidInfo;

    if (androidInfo.version.sdkInt >= 30) {
      if (await Permission.manageExternalStorage.request().isGranted) {
      } else {
        exit(0);
      }
    } else {
      if (await Permission.storage.request().isGranted) {
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
  } else if (Platform.isWindows) {}

  //: run app
  runApp(MultiProvider(
    providers: [
      Provider(create: (ctx) => DriverService()),
      Provider(create: (context) => DriverDbService()),
      Provider(create: (context) => AppConfService()),
      Provider(
        create: (context) => DriverRepo(
          appConfService: context.read(),
          driverService: context.read(),
          dbService: context.read(),
        ),
      ),
      Provider(create: (context) => SelectedFilesState()),
      //
      // VIEW MODELS ----------------------------------------------------------
      //
      Provider(
        create: (context) => ExploreViewModel(
          driverRepo: context.read(),
        ),
      ),
      Provider(
        create: (context) => AddViewModel(
          selectedFilesState: context.read(),
          driverRepo: context.read(),
        ),
      ),
      Provider(
        create: (context) => SelectFileViewModel(
          selectedFilesState: context.read(),
          driverRepo: context.read(),
        ),
      )
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget with WindowListener {
  const MyApp({
    super.key,
  });

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
      onGenerateRoute: (settings) =>
          RouteResolver(currentPath: Uri.parse(settings.name!).path)
              .build(context),
    );
  }
}

class NoAnimationMaterialPageRoute<T> extends MaterialPageRoute<T> {
  NoAnimationMaterialPageRoute({
    required super.builder,
    super.settings,
    super.maintainState = true,
    super.fullscreenDialog = false,
  });

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}

class RouteResolver {
  const RouteResolver({
    required this.currentPath,
  });

  final String currentPath;

  Widget buildRoute(BuildContext context) {
    switch (currentPath) {
      case '/explore':
        return ExploreView(
          exploreViewModel: context.read(),
        );
      case '/add':
        return AddPage(
          addViewModel: context.read(),
        );
      case '/trash':
        return const TrashPage();
      case '/drivers':
        return const DriversPage();
      case '/select-files':
        return SelectFileView(vm: context.read());
      default:
        return Container();
    }
  }

  int routeIndex() {
    switch (currentPath) {
      case '/explore':
        return 0;
      case '/add':
        return 1;
      case '/trash':
        return 2;
      case '/drivers':
        return 3;
      default:
        return 0;
    }
  }

  MaterialPageRoute build(BuildContext context) {
    if (currentPath == '/select-files') {
      return MaterialPageRoute(
        builder: (context) => SelectFileView(
          vm: context.read(),
        ),
      );
    }

    return NoAnimationMaterialPageRoute(
        builder: (context) => MainLayoutWrapper(
              selectedIndex: routeIndex(),
              child: buildRoute(context),
            ));
  }
}
