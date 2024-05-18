import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ftm_flutter/io_manager.dart';
import 'package:path/path.dart';
import 'package:tuple/tuple.dart';

class FileTag {
  const FileTag(
    this.fileName,
    this.tags,
    this.path,
  );

  final String fileName;
  final List<String> tags;
  final String path;

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

  FileTag addTag(String newTag) => FileTag(fileName, [...tags, newTag], path);

  bool equals(FileTag f2) => fileName == f2.fileName && path == f2.path;

  bool isTrashFile() {
    return tags.contains(trashTag);
  }
}

//: ----------------------------------------------------------------------------

Future<void> insertAndMove_(
  FileTag ft,
  /* {bool copy = false} */
) async {
  //: move or copy file
  var f = File(ft.path);
  // TODO copy or move by config, move by default
  await f.copy(join(getCurrntPath(), ft.fileName));
  await f.delete();

  insertDB_(ft);
}

Future<void> insertDB_(FileTag ft) async {
  await Future(() {
    getCurrentDb().execute(
        "INSERT INTO $fileTagTable ($fileNameColumn, $tagsColumn) VALUES ('${ft.fileName}', json('${json.encode(ft.tags)}'));");
  });
}

//: ----------------------------------------------------------------------------

Future<List<FileTag>> getFilesList({
  List<String> includeTags = const [],
  List<String> excludeTags = const [],
}) async {
  List<FileTag> computation() {
    final db = getCurrentDb();

    final conditionList = [
      ...includeTags.map((tag) =>
          "json_string_list_element_exist($tagsColumn ->> '\$', '$tag')"),
      ...excludeTags.map((tag) =>
          "not json_string_list_element_exist($tagsColumn ->> '\$', '$tag')"),
    ];

    final whereClause =
        conditionList.isNotEmpty ? "WHERE ${conditionList.join(" AND ")}" : "";

    final query = "SELECT * FROM $fileTagTable $whereClause;";

    final res = db.select(query);

    return res
        .map(
          (e) => FileTag(
            e[fileNameColumn],
            List<String>.from(
              json.decode(e[tagsColumn]),
            ).where((element) => element != trashTag).toList(),
            join(getCurrntPath(), e[fileNameColumn]),
          ),
        )
        .toList();
  }

  return await Future(computation);
}

Future<Set<String>> tagsList_() => Future(() => Set.from(getCurrentDb()
    .select("SELECT $tagsColumn FROM $fileTagTable;")
    .map((e) => List<String>.from(jsonDecode(e[tagsColumn])))
    .fold<List<String>>(
        [], (previousValue, element) => previousValue + element)));

//: ----------------------------------------------------------------------------

bool checkFileExist(String fileName) {
  final fileExists = File(join(getCurrntPath(), fileName)).existsSync();

  return fileDbExists_(fileName) && fileExists;
}

bool fileDbExists_(String fileName) {
  final db = getCurrentDb();

  final dbExists = db
      .select("SELECT * FROM $fileTagTable WHERE $fileNameColumn = '$fileName'")
      .isNotEmpty;
  return dbExists;
}

class FileTagExistStatus {
  const FileTagExistStatus({required this.exists, required this.notExists});

  final Iterable<FileTag> exists;
  final Iterable<FileTag> notExists;

  FileTagExistStatus addExist(FileTag ft) =>
      FileTagExistStatus(exists: [...exists, ft], notExists: notExists);
  FileTagExistStatus addNotExist(FileTag ft) =>
      FileTagExistStatus(exists: exists, notExists: [...notExists, ft]);
}

Future<FileTagExistStatus> checkAllFilesExist(Iterable<FileTag> files) async {
  return (await Future(
          () => files.map((e) => Tuple2(e, checkFileExist(e.fileName)))))
      .fold<FileTagExistStatus>(
          const FileTagExistStatus(exists: [], notExists: []),
          (acc, i) =>
              i.item2 ? acc.addExist(i.item1) : acc.addNotExist(i.item1));
}

//: ----------------------------------------------------------------------------

class FileExistsException implements Exception {}

Future<void> changeFile(FileTag oldFT, FileTag newFT) async {
  if (oldFT.fileName != newFT.fileName) {
    if (checkFileExist(newFT.fileName)) {
      throw FileExistsException();
    } else {
      var f = File(oldFT.path);
      await f.rename(newFT.path);

      final db = getCurrentDb();

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

  if (!listEquals(newFT.tags, oldFT.tags)) {
    await changeFileTags(newFT, newFT.tags);
  }
}

Future<void> changeFileTags(FileTag ft, List<String> tags) async {
  final db = getCurrentDb();

  await Future(
    () {
      db.execute("""
            UPDATE $fileTagTable
            SET $tagsColumn = '${jsonEncode(tags)}'
            WHERE $fileNameColumn = '${ft.fileName}';
          """);
    },
  );
}

//: ----------------------------------------------------------------------------

void deleteFile(FileTag fileTag) {
  final db = getCurrentDb();

  db.execute(
      "DELETE FROM $fileTagTable WHERE $fileNameColumn = '${fileTag.fileName}';");

  final file = File(join(getCurrntPath(), fileTag.fileName));
  try {
    file.deleteSync();
  } on FileSystemException {
    // ignored
  }
}

//: ----------------------------------------------------------------------------

class IntegrityRes {
  final List<String> filesToBeAddedToDb, dbItemsToBeRemoved;

  IntegrityRes(this.filesToBeAddedToDb, this.dbItemsToBeRemoved);
}

Future<IntegrityRes> checkIntegrity() async {
  String getFileName(File f) {
    return basename(f.path);
  }

  //: check all files in db
  final filesDir = Directory(getCurrntPath());

  final files = (await filesDir.list().toList()).whereType<File>();

  final filesToBeAddedToDb =
      files.where((i) => !fileDbExists_(getFileName(i))).toList();

  for (var file in filesToBeAddedToDb) {
    final ft = FileTag(getFileName(file), [], file.path);
    await insertDB_(ft);
  }

  //: check all db items exist
  final dbFiles = getCurrentDb()
      .select("SELECT $fileNameColumn FROM $fileTagTable;")
      .map<String>((e) => e[fileNameColumn]);

  final dbItemsToBeRemoved =
      dbFiles.where((dbFile) => !files.any((e) => getFileName(e) == dbFile));

  for (var e in dbItemsToBeRemoved) {
    getCurrentDb()
        .execute("DELETE FROM $fileTagTable WHERE $fileNameColumn = '$e';");
  }

  return IntegrityRes(
    filesToBeAddedToDb.map((e) => getFileName(e)).toList(),
    dbItemsToBeRemoved.toList(),
  );
}

//: ----------------------------------------------------------------------------

void restoreTrashFile(FileTag f) {
  changeFileTags(f, f.tags.where((element) => element != trashTag).toList());
}
