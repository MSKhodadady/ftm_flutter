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

// class Old__AppConfService {
//   AppConf _mainConf;

//   Old__AppConfService._raw(this._mainConf);

//   static Future<Old__AppConfService> init() async {
//     final mainConfPath = await _getMainConfPath();
//     final mainConfFile = File(mainConfPath);

//     AppConf mc;

//     if (!(await mainConfFile.exists())) {
//       await mainConfFile.parent.create(recursive: true);
//       mc = AppConf.appStarter();
//     } else {
//       mc = AppConf.fromJson(await mainConfFile.readAsString());
//     }

//     //: write to file
//     _writeMainConf(mc);

//     //: init currentDriver

//     return Old__AppConfService._raw(mc);
//   }

//   static Future<String> _getMainConfPath() async {
//     if (isDesktop()) {
//       return p.join(getHomePath(), _desktopAppConfDir, _mainConfFileName);
//     } else {
//       final supportDir = await getApplicationSupportDirectory();
//       return p.join(
//         supportDir.path,
//         _mainConfFileName,
//       );
//     }
//   }

//   static Future<void> _writeMainConf(AppConf mc) async {
//     final path = await _getMainConfPath();
//     final mainConfFile = File(path);
//     await mainConfFile.writeAsString(jsonEncode(mc.toMap()));
//   }

//   Future<void> withMainConf(
//     FutureOr<AppConf> Function() transformer,
//   ) async {
//     // //: ensure
//     // if (!(await mainConfFile.exists())) {
//     //   await mainConfFile.parent.create(recursive: true);
//     //   _mainConf = _initMainConf();
//     //   await mainConfFile.writeAsString(jsonEncode(_mainConf.toMap()));
//     // } else {
//     //   _mainConf = _mainConfFromJsonString(await mainConfFile.readAsString());
//     // }
//     // final driver = () {
//     //   if (driverName == null) return null;

//     //   final td = _mainConf.drivers
//     //       .firstWhereOrNull((element) => element.name == driverName);

//     //   if (td == null) {
//     //     throw DriverNotExistsException();
//     //   }

//     //   return td;
//     // }();

//     var newMC = await transformer();

//     _writeMainConf(newMC);

//     _mainConf = newMC;
//   }

//   static const driverConfDir = '.config';

//   Future<void> addDriver(Driver newDriver) async {
//     withMainConf(() {
//       if (_mainConf.drivers.any((element) =>
//           element.name == newDriver.name || element.path == newDriver.path)) {
//         throw DriverExistsException();
//       }

//       return AppConf(
//           [..._mainConf.drivers, newDriver], _mainConf.currentDriver);
//     });
//   }

//   Future<void> renameDriver(String driverName, String newName) async {
//     await withMainConf(() {
//       final neoDs = _mainConf.drivers
//           .map(
//             (e) => e.name == driverName
//                 ? Driver(name: newName, path: e.path, type: e.type)
//                 : e,
//           )
//           .toList();

//       return AppConf(
//           neoDs,
//           _mainConf.currentDriver == driverName
//               ? newName
//               : _mainConf.currentDriver);
//     });
//   }

//   Future<void> removeDriver(String driverName) async {
//     await withMainConf(() {
//       if (_mainConf.drivers.length < 2) {
//         throw Exception("one-driver");
//       }

//       if (_mainConf.currentDriver == driverName) {
//         throw Exception("current");
//       }

//       var neoDs = _mainConf.drivers
//           .where((element) => element.name != driverName)
//           .toList();

//       return AppConf(neoDs, _mainConf.currentDriver);
//     });
//   }
// }

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

  Future<void> _writeAppConf(AppConf mc) async {
    final path = await _getMainConfPath();
    final mainConfFile = File(path);
    await mainConfFile.writeAsString(jsonEncode(mc.toMap()));
  }

  Future<AppConf> forceRemove(AppConf mc, Driver driver) async {
    final neoDs =
        mc.drivers.where((element) => element.name != driver.name).toList();
    AppConf newMc;

    if (neoDs.isEmpty) {
      newMc = AppConf.appStarter();
    } else {
      newMc = AppConf(
        neoDs,
        mc.currentDriver == driver.name ? neoDs[0].name : mc.currentDriver,
      );
    }
    await _writeAppConf(newMc);

    return mc;
  }
}
