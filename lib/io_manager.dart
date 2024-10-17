import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

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

  Driver({
    required this.name,
    required this.path,
    required this.type,
  });

  Driver.fromMap(Map<String, dynamic> m)
      : this(
          name: m['name'],
          path: m['path'],
          type: m['type'],
        );

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'path': path,
      'type': type,
    };
  }
}

const _mainDriverName = 'FTM';
const _desktopAppConfDir = '.ftm'; //: for windows, linux, mac os
const _mainConfFileName = 'app-conf.json';

const _driverConfDir = '.config';

bool isDesktop() => Platform.isLinux || Platform.isWindows || Platform.isLinux;

// APP IO STATE ----------------------------------------------------------------

Database? _currentDb;
var _mainConf = MainConf([], '');

// -----------------------------------------------------------------------------

class MainConf {
  static const _mainConfDriversKey = 'drivers';
  static const _currentDriverKey = 'current';

  final List<Driver> drivers;
  final String currentDriver;

  MainConf(this.drivers, this.currentDriver);

  Map<String, dynamic> toMap() {
    return {
      _mainConfDriversKey: drivers.map((e) => e.toMap()).toList(),
      _currentDriverKey: currentDriver,
    };
  }
}

MainConf _mainConfFromJsonString(String mc) {
  final mfMap = jsonDecode(mc);

  final drivers = (mfMap[MainConf._mainConfDriversKey] as List<dynamic>)
      .map<Driver>((e) => Driver.fromMap(e))
      .toList();

  final currentDriverInJson = mfMap[MainConf._currentDriverKey] as String;
  final currentDriver = drivers.firstWhereOrNull(
              (element) => element.name == currentDriverInJson) ==
          null
      ? drivers[0].name
      : currentDriverInJson;

  return MainConf(drivers, currentDriver);
}

MainConf _initMainConf() {
  final mainDriver = Driver(
    name: _mainDriverName,
    path: p.join(getHomePath(), _mainDriverName),
    type: 'file',
  );

  return MainConf([mainDriver], _mainDriverName);
}

Future<void> initApp() async {
  //: check config folder
  await _withMainConf(null, (m, _) async {
    final currentDriverFound = _mainConf.drivers
        .firstWhereOrNull((element) => element.name == m.currentDriver);

    if (currentDriverFound == null) {
      final currentDriver = m.drivers[0];

      final dir = Directory(p.join(currentDriver.path, _driverConfDir));
      if (!(await dir.exists())) {
        await dir.create(recursive: true);
      }

      _currentDb = await _initDB(dir.path);

      return MainConf(m.drivers, currentDriver.name);
    } else {
      final dir = Directory(p.join(currentDriverFound.path, _driverConfDir));
      if (!(await dir.exists())) {
        await dir.create(recursive: true);
      }

      _currentDb = await _initDB(dir.path);

      return m;
    }
  });
}

Database getCurrentDb() {
  return _currentDb!;
}

String getCurrntPath() {
  //: TODO: check conf file and current driver are currect
  return _mainConf.drivers
      .firstWhere((element) => element.name == _mainConf.currentDriver)
      .path;
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

Future<String> _getMainConfPath() async {
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

/// This function, gets [driverName] and a [transformer] function.
/// First this functions loads the [MainConf] and gives it to [transformer] with the driver with name [driverName]/
/// Then, the [transformer] changes the [MainConf], and returns new [MainConf].
/// Then, this function saves the [MainConf] to file again.
Future<MainConf> _withMainConf(
  String? driverName,
  FutureOr<MainConf> Function(MainConf m, Driver? d) transformer,
) async {
  final mainConfFile = File(await _getMainConfPath());

  //: ensure
  if (!(await mainConfFile.exists())) {
    await mainConfFile.parent.create(recursive: true);
    _mainConf = _initMainConf();
    await mainConfFile.writeAsString(jsonEncode(_mainConf.toMap()));
  } else {
    _mainConf = _mainConfFromJsonString(await mainConfFile.readAsString());
  }
  final driver = () {
    if (driverName == null) return null;

    final td = _mainConf.drivers
        .firstWhereOrNull((element) => element.name == driverName);

    if (td == null) {
      throw DriverNotExistsException();
    }

    return td;
  }();

  _mainConf = await transformer(_mainConf, driver);

  await mainConfFile.writeAsString(jsonEncode(_mainConf.toMap()));

  return _mainConf;
}

MainConf getMainConf() {
  return _mainConf;
}

class DriverExistsException implements Exception {}

class DriverNotExistsException implements Exception {}

Future<void> addDriver(Driver newDriver) async {
  _withMainConf(null, (m, _) {
    if (m.drivers.any((element) =>
        element.name == newDriver.name || element.path == newDriver.path)) {
      throw DriverExistsException();
    }

    return MainConf([...m.drivers, newDriver], m.currentDriver);
  });
}

Future<void> renameDriver(String driverName, String newName) async {
  await _withMainConf(driverName, (m, d) {
    final neoDs = m.drivers
        .map(
          (e) => e.name == driverName
              ? Driver(name: newName, path: e.path, type: e.type)
              : e,
        )
        .toList();

    return MainConf(
        neoDs, m.currentDriver == driverName ? newName : m.currentDriver);
  });
}

Future<void> setCurrentDriver(String driverName) async {
  await _withMainConf(driverName, (m, d) async {
    final dir = Directory(p.join(d!.path, _driverConfDir));
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }

    _currentDb = await _initDB(dir.path);

    return MainConf(m.drivers, d.name);
  });
}

Future<void> removeDriver(String driverName) async {
  await _withMainConf(driverName, (m, d) {
    if (m.drivers.length < 2) {
      throw Exception("one-driver");
    }

    if (m.currentDriver == d!.name) {
      throw Exception("current");
    }

    var neoDs =
        m.drivers.where((element) => element.name != driverName).toList();

    return MainConf(neoDs, m.currentDriver);
  });
}
