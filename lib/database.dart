import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ftm_flutter/files.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

String _dbPath = "";
Database? _db;

Future<void> initDB() async {
  // TODO it's just for android.
  // _dbPath = p.join((await getApplicationSupportDirectory()).path, 'ftm.db');
  _dbPath = p.join(configFilesPath, 'ftm.db');

  _db ??= sqlite3.open(_dbPath);

  final dbVersion =
      _db?.select("PRAGMA user_version").first['user_version'] as int;
  if (kDebugMode) print("current database version is: $dbVersion");

  if (dbVersion < 1) {
    _db?.execute('CREATE TABLE fileTag (fileName TEXT PRIMARY KEY, tags JSON)');
  }

  //: IMPORTANT {
  const lastDbVersion = 1;
  //: }

  if (dbVersion != lastDbVersion) {
    _db?.execute("PRAGMA user_version = $lastDbVersion");

    final myLastDbVersion =
        _db?.select("PRAGMA user_version").first['user_version'] as int;
    if (kDebugMode) print("The last db version is: $myLastDbVersion");
  }

  _registerDBFunctions(_db!);
}

void _registerDBFunctions(Database db) {
  db.createFunction(
      functionName: 'json_string_list_element_exist',
      argumentCount: const AllowedArgumentCount(2),
      deterministic: true,
      function: (args) => List<String>.from(json.decode(args[0] as String))
          .contains(args[1] as String));
}

String getDBPath() {
  return _dbPath;
}

Database getDB_() {
  if (_db == null) {
    _db = sqlite3.open(_dbPath);
    _registerDBFunctions(_db!);
  }

  return _db!;
}

const fileTagTable = "fileTag";
const fileNameColumn = "fileName";
const tagsColumn = "tags";
