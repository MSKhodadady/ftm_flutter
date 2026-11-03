import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:sqlite3/sqlite3.dart';

const fileTagTable = "fileTag";
const fileNameColumn = "fileName";
const tagsColumn = "tags";

class DriverDbService {
  DriverDbService();

  void _registerDBFunctions(Database db) {
    db.createFunction(
        functionName: 'json_string_list_element_exist',
        argumentCount: const AllowedArgumentCount(2),
        deterministic: true,
        function: (args) => List<String>.from(json.decode(args[0] as String))
            .contains(args[1] as String));
  }

  Future<Database> initDB(String path) async {
    final db = sqlite3.open(path);

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

  Future<void> insertFT(FileTag ft, Database db) async {
    await Future(() {
      db.execute(
          "INSERT INTO $fileTagTable ($fileNameColumn, $tagsColumn) VALUES (?1, json(?2));",
          [ft.fileName, json.encode(ft.tags)]);
    });
  }

  Iterable<String> getAllItems(Database db) {
    final dbFiles = db
        .select("SELECT $fileNameColumn FROM $fileTagTable;")
        .map<String>((e) => e[fileNameColumn]);

    return dbFiles;
  }

  void deleteFileTag(String fileName, Database db) {
    db.execute(
        "DELETE FROM $fileTagTable WHERE $fileNameColumn = '$fileName';");
  }

  ResultSet findByFileName(String fileName, Database db) {
    final result = db.select(
        "SELECT * FROM $fileTagTable WHERE $fileNameColumn = ?1;", [fileName]);

    return result;
  }
}
