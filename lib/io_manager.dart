import 'dart:async';
import 'dart:io';
import 'package:ftm_flutter/db_service.dart';
import 'package:ftm_flutter/driver_service.dart';
import 'package:ftm_flutter/main_conf_repo.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

const trashTag = '__TRASH';

bool isDesktop() => Platform.isLinux || Platform.isWindows || Platform.isLinux;

Future<void> initApp() async {
  //: check config folder
  await Old__AppConfService.withMainConf(() async {
    final currentDriverFound = Old__AppConfService.getMainConf()
        .drivers
        .firstWhereOrNull((element) => element.name == m.currentDriver);

    if (currentDriverFound == null) {
      final currentDriver = m.drivers[0];

      final dir =
          Directory(p.join(currentDriver.path, DriverService.driverConfDir));
      if (!(await dir.exists())) {
        await dir.create(recursive: true);
      }

      DBService.initDB(dir.path);

      return AppConf(m.drivers, currentDriver.name);
    } else {
      final dir = Directory(
          p.join(currentDriverFound.path, DriverService.driverConfDir));
      if (!(await dir.exists())) {
        await dir.create(recursive: true);
      }

      DBService.initDB(dir.path);

      return m;
    }
  });
}

String getHomePath() {
  return Platform.isAndroid
      ? "/sdcard"
      : Platform.isLinux
          ? Platform.environment['HOME']!
          : Platform.isWindows
              ? Platform.environment['UserProfile']!
              : '';
}
