import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ftm_flutter/data/file_item.dart';
import 'package:ftm_flutter/database.dart';
import 'package:ftm_flutter/files.dart';
import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tuple/tuple.dart';

class FileTag {
  const FileTag(this.fileName, this.tags) : empty = false;
  FileTag.empty()
      : fileName = "",
        tags = [],
        empty = true;

  final String fileName;
  final List<String> tags;
  final bool empty;

  List<Map<String, String>> toMaps() {
    return tags.map((tag) => {'fileName': fileName, 'tag': tag}).toList();
  }

  static List<FileTag> aggregate(Iterable<FileTag> fileTags) {
    return fileTags.fold<Iterable<FileTag>>(
        [],
        (fileTags, element) => fileTags
                .any((ft) => ft.fileName == element.fileName)
            ? fileTags.map((e) =>
                element.fileName == e.fileName ? e.addTag(element.tags[0]) : e)
            : [...fileTags, element]).toList();
  }

  FileTag addTag(String newTag) => FileTag(fileName, [...tags, newTag]);
}

class FileTagExistStatus {
  const FileTagExistStatus({required this.exists, required this.notExists});

  final Iterable<FileItem> exists;
  final Iterable<FileItem> notExists;

  FileTagExistStatus addExist(FileItem ft) =>
      FileTagExistStatus(exists: [...exists, ft], notExists: notExists);
  FileTagExistStatus addNotExist(FileItem ft) =>
      FileTagExistStatus(exists: exists, notExists: [...notExists, ft]);
}

Future<void> insertAndMove_(
  FileTag ft,
  String path,
  /* {bool copy = false} */
) async {
  //: move or copy file
  var f = File(path);
  // TODO copy or move by config, move by default
  await f.copy(join(filesPath, ft.fileName));
  await f.delete();

  insertDB_(ft);
}

Future<void> insertDB_(FileTag ft) async {
  await Future(() {
    final db = sqlite3.open(getDBPath());
    db.execute(
        "INSERT INTO $fileTagTable ($fileNameColumn, $tagsColumn) VALUES ('${ft.fileName}', json('${json.encode(ft.tags)}'));");
  });
}

Future<List<FileTag>> filesListTagFilter_(List<String> chosenTags) async {
  List<FileTag> computation() {
    final db = getDB_();

    final whereClause = chosenTags.isNotEmpty
        ? "WHERE ${chosenTags.map((tag) => "json_string_list_element_exist($tagsColumn ->> '\$', '$tag')").join(" AND ")}"
        : "";

    final query = "SELECT * FROM $fileTagTable $whereClause;";

    final res = db.select(query);

    return res
        .map((e) => FileTag(
            e[fileNameColumn], List<String>.from(json.decode(e[tagsColumn]))))
        .toList();
  }

  return await Future(computation);
}

Future<Set<String>> tagsList_() => Future(() => Set.from(sqlite3
    .open(getDBPath())
    .select("SELECT $tagsColumn FROM $fileTagTable;")
    .map((e) => List<String>.from(jsonDecode(e[tagsColumn])))
    .fold<List<String>>(
        [], (previousValue, element) => previousValue + element)));

bool checkFileExist(String fileName) {
  final fileExists = File(join(filesPath, fileName)).existsSync();

  return fileDbExists_(fileName) && fileExists;
}

bool fileDbExists_(String fileName) {
  final db = getDB_();

  final dbExists = db
      .select("SELECT * FROM $fileTagTable WHERE $fileNameColumn = '$fileName'")
      .isNotEmpty;
  return dbExists;
}

Future<FileTagExistStatus> checkAllFilesExist(Iterable<FileItem> files) async {
  return (await Future(
          () => files.map((e) => Tuple2(e, checkFileExist(e.name)))))
      .fold<FileTagExistStatus>(
          const FileTagExistStatus(exists: [], notExists: []),
          (acc, i) =>
              i.item2 ? acc.addExist(i.item1) : acc.addNotExist(i.item1));
}

Future<void> changeFile(FileTag oldFT, FileTag newFT) async {
  if (oldFT.fileName != newFT.fileName) {
    if (checkFileExist(newFT.fileName)) {
      throw FileExists();
    } else {
      var f = File(join(filesPath, oldFT.fileName));
      await f.rename(join(filesPath, newFT.fileName));

      final db = getDB_();

      await Future(
        () {
          db.execute("""
            UPDATE $fileTagTable
            SET $fileNameColumn = '${newFT.fileName}'
            WHERE $fileNameColumn = '${oldFT.fileName}';
          """);
        },
      );
    }
  }

  if (!listEquals(oldFT.tags, newFT.tags)) {
    final db = getDB_();

    await Future(
      () {
        db.execute("""
            UPDATE $fileTagTable
            SET $tagsColumn = '${jsonEncode(newFT.tags)}'
            WHERE $fileNameColumn = '${newFT.fileName}';
          """);
      },
    );
  }
}

class FileExists implements Exception {}

void deleteFile(FileTag fileTag) {
  final db = getDB_();

  db.execute(
      "DELETE FROM $fileTagTable WHERE $fileNameColumn = '${fileTag.fileName}';");

  final file = File(join(filesPath, fileTag.fileName));
  try {
    file.deleteSync();
  } on FileSystemException {
    // ignored
  }
}

class IntegrityRes {
  final List<String> filesToBeAddedToDb, dbItemsToBeRemoved;

  IntegrityRes(this.filesToBeAddedToDb, this.dbItemsToBeRemoved);
}

Future<IntegrityRes> checkIntegrity() async {
  //: check all files in db
  final filesDir = Directory(filesPath);
  final fileNames = (await filesDir.list().toList())
      .whereType<File>()
      .map((e) => basename(e.path));

  final filesToBeAddedToDb =
      fileNames.where((element) => !fileDbExists_(element)).toList();

  for (var fileName in filesToBeAddedToDb) {
    final ft = FileTag(fileName, []);
    await insertDB_(ft);
  }

  //: check all db items exist
  final dbFiles = getDB_()
      .select("SELECT $fileNameColumn FROM $fileTagTable;")
      .map<String>((e) => e[fileNameColumn]);

  final dbItemsToBeRemoved =
      dbFiles.where((dbFile) => !fileNames.any((e) => e == dbFile));

  for (var e in dbItemsToBeRemoved) {
    getDB_().execute("DELETE FROM $fileTagTable WHERE $fileNameColumn = '$e';");
  }

  return IntegrityRes(filesToBeAddedToDb, dbItemsToBeRemoved.toList());
}
