import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ftm_flutter/models/file_tag.dart';
import 'package:ftm_flutter/services/database.dart';
import 'package:path/path.dart';
import 'package:tuple/tuple.dart';
import 'package:path/path.dart' as p;

Future<Set<String>> tagsList_() => Future(() => Set.from(getCurrentDb()
    .select("SELECT $tagsColumn FROM $fileTagTable;")
    .map((e) => List<String>.from(jsonDecode(e[tagsColumn])))
    .fold<List<String>>(
        [], (previousValue, element) => previousValue + element)));

class FileExistsException implements Exception {}
