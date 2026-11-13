import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ftm_flutter/models/file_tag.dart';
import 'package:ftm_flutter/services/database.dart';
import 'package:path/path.dart';
import 'package:tuple/tuple.dart';
import 'package:path/path.dart' as p;

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
            ).where((element) => element != FileTag.trashTag).toList(),
            join(getCurrentDriverPath(), e[fileNameColumn]),
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

class FileExistsException implements Exception {}

void deleteFile(FileTag fileTag) {
  final db = getCurrentDb();

  db.execute(
      "DELETE FROM $fileTagTable WHERE $fileNameColumn = '${fileTag.fileName}';");

  final file = File(join(getCurrentDriverPath(), fileTag.fileName));
  try {
    file.deleteSync();
  } on FileSystemException {
    // ignored
  }
}

void restoreTrashFile(FileTag f) {
  changeFileTags(
      f, f.tags.where((element) => element != FileTag.trashTag).toList());
}
