import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:ftm_flutter/services/database.dart';

class FileTag {
  static const String trashTag = '__TRASH';

  const FileTag(
    this.fileName,
    this.tags,
    this.path,
  );

  factory FileTag.fromMap(Map<String, dynamic> e, String currentDriverPath) {
    return FileTag(
      e[fileNameColumn],
      List<String>.from(
        json.decode(e[tagsColumn]),
      ).where((element) => element != FileTag.trashTag).toList(),
      p.join(currentDriverPath, e[fileNameColumn]),
    );
  }

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
