import 'dart:convert';
import 'dart:isolate';
import 'package:ftm_flutter/models/file_tag.dart';
import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';

const fileTagTable = "fileTag";
const fileNameColumn = "fileName";
const tagsColumn = "tags";
const mainDbFileName = 'ftm.db';
const mainDbFolder = 'data';

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
    Database compute() {
      final db = sqlite3.open(path);

      final dbVersion =
          db.select("PRAGMA user_version").first['user_version'] as int;
      if (kDebugMode) print("current database version is: $dbVersion");

      //: migration 1
      if (dbVersion < 1) {
        db.execute(
            'CREATE TABLE fileTag (fileName TEXT PRIMARY KEY, tags JSON)');
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

    return Isolate.run(compute);
  }

  Future<void> insertFT(FileTag ft, Database db) async {
    await Isolate.run(() {
      db.execute(
          "INSERT INTO $fileTagTable ($fileNameColumn, $tagsColumn) VALUES (?1, json(?2));",
          [ft.fileName, json.encode(ft.tags)]);
    });
  }

  Future<Iterable<String>> getAllItems(Database db) {
    return Isolate.run(() => db
        .select("SELECT $fileNameColumn FROM $fileTagTable;")
        .map<String>((e) => e[fileNameColumn]));
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

  //: TODO: add pagination
  Future<ResultSet> getFiles({
    required Database db,
    List<String> includeTags = const [],
    List<String> excludeTags = const [],
  }) {
    return Isolate.run(() {
      final conditionList = [
        ...includeTags.map((tag) =>
            "json_string_list_element_exist($tagsColumn ->> '\$', '$tag')"),
        ...excludeTags.map((tag) =>
            "not json_string_list_element_exist($tagsColumn ->> '\$', '$tag')"),
      ];

      final whereClause = conditionList.isNotEmpty
          ? "WHERE ${conditionList.join(" AND ")}"
          : "";

      final query = "SELECT * FROM $fileTagTable $whereClause;";

      final res = db.select(query);

      return res;
    });
  }

  Future<void> changeFileTags(
      Database db, FileTag ft, List<String> tags) async {
    await Isolate.run(
      () {
        db.execute("""
            UPDATE $fileTagTable
            SET $tagsColumn = '${jsonEncode(tags)}'
            WHERE $fileNameColumn = '${ft.fileName}';
          """);
      },
    );
  }

  bool fileDbExists(Database db, String fileName) {
    final dbExists = db.select(
        "SELECT * FROM $fileTagTable WHERE $fileNameColumn = ?1",
        [fileName]).isNotEmpty;
    return dbExists;
  }

  Future<void> rename(
      Database db, String oldFileName, String newFileName) async {
    await Isolate.run(() {
      db.execute("""
            UPDATE $fileTagTable
            SET $fileNameColumn = '$newFileName'
            WHERE $fileNameColumn = '$oldFileName';
          """);
    });
  }
}
