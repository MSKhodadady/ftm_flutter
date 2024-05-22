import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:tuple/tuple.dart';

//: DB -------------------------------------------------------------------------

const databaseFileName = 'ftm.db';

Future<Database> _initDB(String confPath) async {
  final db = sqlite3.open(p.join(confPath, databaseFileName));

  final dbVersion =
      db.select("PRAGMA user_version").first['user_version'] as int;
  if (kDebugMode) print("current database version is: $dbVersion");

  //: migration 1
  if (dbVersion < 1) {
    db.execute('CREATE TABLE fileTag (fileName TEXT PRIMARY KEY, tags JSON)');
  }

  //: IMPORTANT {
  const lastDbVersion = 1;
  //: }

  //: set migration version to last one
  if (dbVersion != lastDbVersion) {
    db.execute("PRAGMA user_version = $lastDbVersion");

    final myLastDbVersion =
        db.select("PRAGMA user_version").first['user_version'] as int;
    if (kDebugMode) print("The last db version is: $myLastDbVersion");
  }

  _registerDBFunctions(db);

  return db;
}

void _registerDBFunctions(Database db) {
  db.createFunction(
      functionName: 'json_string_list_element_exist',
      argumentCount: const AllowedArgumentCount(2),
      deterministic: true,
      function: (args) => List<String>.from(json.decode(args[0] as String))
          .contains(args[1] as String));
}

const fileTagTable = "fileTag";
const fileNameColumn = "fileName";
const tagsColumn = "tags";

const trashTag = '__TRASH';

//: DRIVER ---------------------------------------------------------------------

class Driver {
  final String name;
  final String path;
  final String type;
  final bool current;

  Driver(
      {required this.name,
      required this.path,
      required this.type,
      required this.current});

  Driver.fromMap(Map<String, dynamic> m)
      : this(
            name: m['name'],
            path: m['path'],
            type: m['type'],
            current: m['current']);

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'path': path,
      'type': type,
      'current': current,
    };
  }
}

const _mainDriverName = 'FTM';
const _desktopAppConfDir = '.ftm'; //: for windows, linux, mac os
const _mainConfFileName = 'app-conf.json';
const _mainConfDriversKey = 'drivers';
const _driverConfDir = '.config';

bool isDesktop() => Platform.isLinux || Platform.isWindows || Platform.isLinux;

List<Driver> _drivers = [];
Database? _currentDb;

Future<void> initApp() async {
  //: check config folder

  if (isDesktop()) {
    final home = homePath();

    final appConfDir = Directory(p.join(home, _desktopAppConfDir));

    if (!(await appConfDir.exists())) {
      await appConfDir.create(recursive: true);
    }

    final mainAppConfFile = File(p.join(appConfDir.path, _mainConfFileName));

    _drivers = await () async {
      List<Driver> init() {
        final mainDriver = Driver(
            name: _mainDriverName,
            path: p.join(home, _mainDriverName),
            type: 'file',
            current: true);

        mainAppConfFile.writeAsString(
          jsonEncode({
            _mainConfDriversKey: [mainDriver.toMap()]
          }),
        );

        return [mainDriver];
      }

      if (!(await mainAppConfFile.exists())) {
        return init();
      } else {
        try {
          final mainAppConfJson =
              jsonDecode(await mainAppConfFile.readAsString());

          List<Map<String, dynamic>>? driversMaps =
              mainAppConfJson[_mainConfDriversKey];

          if (driversMaps == null) {
            throw Exception();
          }

          return driversMaps.map((e) => Driver.fromMap(e)).toList();
        } catch (e) {
          // ignore: avoid_print
          print(e);

          return init();
        }
      }
    }();

    //: init conf dir and db for current driver
    final currentDriver = _drivers.firstWhere((element) => element.current);

    final dir = Directory(p.join(currentDriver.path, _driverConfDir));
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }

    _currentDb = await _initDB(dir.path);

    return;
  } else {
    //: TODO: check for android, "/storage/emulated/0" or "/sdcard"
    // return p.join(_homePath(), _mainFolderName);
  }
}

Database getCurrentDb() {
  return _currentDb!;
}

String getCurrntPath() {
  return _drivers.firstWhere((element) => element.current).path;
}

String homePath() {
  return Platform.isAndroid
      ? "/sdcard"
      : Platform.isLinux
          ? Platform.environment['HOME']!
          : Platform.isWindows
              ? Platform.environment['UserProfile']!
              : '';
}

String _getMainConfPath() {
  if (isDesktop()) {
    return p.join(homePath(), _desktopAppConfDir, _mainConfFileName);
  } else {
    throw Exception("not implemented");
  }
}

Future<void> _writeMainConf(List<Driver> ds) async {
  final mainConfFile = File(_getMainConfPath());

  if (!(await mainConfFile.parent.exists())) {
    await mainConfFile.parent.create(recursive: true);
  }

  await mainConfFile.writeAsString(
    jsonEncode({_mainConfDriversKey: ds.map((e) => e.toMap())}),
  );

  _drivers = ds;
}

List<Driver> getDrivers() {
  return _drivers;
}

class DriverExistsException implements Exception {}

class DriverNotExistsException implements Exception {}

Future<void> addDriver(Driver newDriver) async {
  final drivers = getDrivers();

  if (drivers.any((element) =>
      element.name == newDriver.name || element.path == newDriver.path)) {
    throw DriverExistsException();
  }

  final newDrivers = [...drivers, newDriver];

  await _writeMainConf(newDrivers);
}

Tuple2<List<Driver>, Driver> _getDriverOrThrow(String driverName) {
  final drivers = getDrivers();

  final targetD =
      drivers.firstWhereOrNull((element) => element.name == driverName);

  if (targetD == null) {
    throw DriverNotExistsException();
  }

  return Tuple2(drivers, targetD);
}

Future<void> renameDriver(String driverName, String newName) async {
  final k = _getDriverOrThrow(driverName);
  final drivers = k.item1;

  final neoDs = drivers
      .map(
        (e) => e.name == driverName
            ? Driver(
                name: newName, path: e.path, type: e.type, current: e.current)
            : e,
      )
      .toList();

  await _writeMainConf(neoDs);
}

Future<void> setCurrentDriver(String driverName) async {
  final k = _getDriverOrThrow(driverName);
  final drivers = k.item1;
  final d = k.item2;

  final neoDs = drivers
      .map(
        (e) => e.name == driverName
            ? Driver(name: e.name, path: e.path, type: e.type, current: true)
            : e,
      )
      .toList();

  await _writeMainConf(neoDs);

  //: set current db
  final dir = Directory(p.join(d.path, _driverConfDir));
  if (!(await dir.exists())) {
    await dir.create(recursive: true);
  }

  _currentDb = await _initDB(dir.path);
}

Future<void> removeDriver(String driverName) async {
  final k = _getDriverOrThrow(driverName);
  final drivers = k.item1;
  final d = k.item2;

  if (drivers.length < 2) {
    throw Exception("one-driver");
  }

  if (d.current) {
    throw Exception("current");
  }

  var neoDs = drivers.where((element) => element.name != driverName).toList();

  _writeMainConf(neoDs);
}
