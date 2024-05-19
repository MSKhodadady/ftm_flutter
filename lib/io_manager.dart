import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
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
