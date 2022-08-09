import 'dart:io';
import 'package:ftm_flutter/data/file_item.dart';
import 'package:ftm_flutter/database.dart';
import 'package:ftm_flutter/files.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class FileTag {
  const FileTag(this.fileName, this.tags);

  final String fileName;
  final List<String> tags;

  List<Map<String, String>> toMaps() {
    return tags.map((tag) => {'fileName': fileName, 'tag': tag}).toList();
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

Future<FileTagExistStatus> checkFilesExist(Iterable<FileItem> fileTags) async {
  final db = await getDB();

  return fileTags.fold<Future<FileTagExistStatus>>(
      Future.value(const FileTagExistStatus(exists: [], notExists: [])),
      (previousValueF, element) async {
    final previousValue = await previousValueF;
    return (
            //: file exist in directory
            File(join(filesPath, element.name)).existsSync() &&
                //: file exist in db
                (await db.query(fileTagTable,
                        distinct: true,
                        where: "$fileNameColumn == '${element.name}'"))
                    .isNotEmpty)
        ? previousValue.addExist(element)
        : previousValue.addNotExist(element);
  });
}

Future<void> insertAndMove(FileTag ft, path, bool copy) async {
  final db = await getDB();

  //: move or copy file
  var f = File(path);
  if (copy) {
    await f.copy(join(filesPath, ft.fileName));
  } else {
    await f.rename(join(filesPath, ft.fileName));
  }

  //: add file to db
  Future.wait(ft.toMaps().map((e) =>
      db.insert('fileTag', e, conflictAlgorithm: ConflictAlgorithm.replace)));
}

Future<List<String>> tagsList() async {
  final db = await getDB();

  return (await db.query("fileTag", columns: ["tag"], distinct: true))
      .map((e) => e['tag'] as String)
      .toList();
}

Future<List<FileTag>> filesList(/* List<String> chosenTags */) async {
  final db = await getDB();

  final output = (await db.query("fileTag"))
      //: convert to FileTag
      .map<FileTag>(
          (e) => FileTag(e[fileNameColumn] as String, [e[tagColumn] as String]))
      //: aggregate
      .fold<Iterable<FileTag>>(
          [],
          (fileTags, element) =>
              fileTags.any((ft) => ft.fileName == element.fileName)
                  ? fileTags.map((e) => element.fileName == e.fileName
                      ? e.addTag(element.tags[0])
                      : e)
                  : [...fileTags, element]).toList();
  return output;
}
