import 'dart:async';
import 'package:ftm_flutter/util/io.dart';
import 'dart:convert';
import 'dart:io';
import 'package:ftm_flutter/models/app_conf.dart';
import 'package:ftm_flutter/models/driver.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _desktopAppConfDir = '.ftm'; //: for windows, linux, mac os
const _mainConfFileName = 'app-conf.json';

class AppConfService {
  static Future<String> _getMainConfPath() async {
    if (isDesktop()) {
      return p.join(getHomePath(), _desktopAppConfDir, _mainConfFileName);
    } else {
      final supportDir = await getApplicationSupportDirectory();
      return p.join(
        supportDir.path,
        _mainConfFileName,
      );
    }
  }

  Future<AppConf> readAppConf() async {
    final mainConfPath = await _getMainConfPath();
    final mainConfFile = File(mainConfPath);

    AppConf mc;
    if (!mainConfFile.existsSync()) {
      await mainConfFile.parent.create(recursive: true);
      mc = AppConf.appStarter();
    } else {
      mc = AppConf.fromJson(await mainConfFile.readAsString());
    }

    _writeAppConf(mc);

    return mc;
  }

  Future<void> _writeAppConf(AppConf newAc) async {
    final path = await _getMainConfPath();
    final mainConfFile = File(path);
    await mainConfFile.writeAsString(jsonEncode(newAc.toMap()));
  }

  // Future<AppConf> forceRemove(Driver driver) async {
  //   final ac = await readAppConf();

  //   final neoDs =
  //       ac.drivers.where((element) => element.name != driver.name).toList();

  //   AppConf newAc;

  //   if (neoDs.isEmpty) {
  //     newAc = AppConf.appStarter();
  //   } else {
  //     newAc = AppConf(
  //       neoDs,
  //       ac.currentDriver == driver.name ? neoDs[0].name : ac.currentDriver,
  //     );
  //   }
  //   await _writeAppConf(newAc);

  //   return newAc;
  // }

  Future<AppConf> addDriver(Driver newDriver) async {
    final ac = await readAppConf();

    if (ac.drivers.any(
      (element) =>
          element.name == newDriver.name || element.path == newDriver.path,
    )) {
      throw DriverExistsException(
          sameName: ac.drivers.any(
            (element) => element.name == newDriver.name,
          ),
          samePath: ac.drivers.any(
            (element) => element.path == newDriver.path,
          ));
    }

    final newAC = AppConf([...ac.drivers, newDriver], ac.currentDriver);

    _writeAppConf(newAC);

    return newAC;
  }

  Future<AppConf> renameDriver(String driverName, String newName) async {
    final ac = await readAppConf();

    final neoDs = ac.drivers
        .map(
          (e) => e.name == driverName
              ? Driver(name: newName, path: e.path, type: e.type)
              : e,
        )
        .toList();

    var newAc = AppConf(
      neoDs,
      ac.currentDriver == driverName ? newName : ac.currentDriver,
    );

    _writeAppConf(newAc);

    return newAc;
  }

  Future<AppConf> deleteDriver(String driverName) async {
    final ac = await readAppConf();

    if (ac.drivers.length < 2) {
      throw Exception("one-driver");
    }

    if (ac.currentDriver == driverName) {
      throw Exception("current");
    }

    var neoDs =
        ac.drivers.where((element) => element.name != driverName).toList();

    var newAc = AppConf(neoDs, ac.currentDriver);
    _writeAppConf(newAc);

    return newAc;
  }

  Future<AppConf> setCurrentDriver(String driverName) async {
    final ac = await readAppConf();

    if (!ac.drivers.any((element) => element.name == driverName)) {
      throw DriverNotFoundException();
    }

    var newAc = AppConf(ac.drivers, driverName);
    _writeAppConf(newAc);

    return newAc;
  }
}

class DriverExistsException extends Error {
  final bool sameName;
  final bool samePath;

  DriverExistsException({required this.sameName, required this.samePath});
}

class DriverNotFoundException extends Error {}
