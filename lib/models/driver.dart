import 'dart:io';

import 'package:ftm_flutter/models/app_conf.dart';
import 'package:sqlite3/sqlite3.dart';

class Driver {
  final String name;
  final String path;
  final String type;

  const Driver({
    required this.name,
    required this.path,
    required this.type,
  });

  factory Driver.fromMap(Map<String, dynamic> m) {
    final name = m['name'], path = m['path'], type = m['type'];
    final correct = name is String && path is String && type is String;

    assert(correct, 'driver map is not correct');

    return Driver(
      name: name,
      path: path,
      type: type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'path': path,
      'type': type,
    };
  }
}

class DriverDatabase extends Driver {
  final Database db;

  const DriverDatabase({
    required super.name,
    required super.path,
    required super.type,
    required this.db,
  });
}

class DriverSyncResult {
  final AppConf appConf;
  final DriverDatabase currentDriver;
  final Iterable<String> dbItemsToBeRemoved;
  final Iterable<File> filesToBeAddedToDb;

  const DriverSyncResult({
    required this.currentDriver,
    required this.dbItemsToBeRemoved,
    required this.filesToBeAddedToDb,
    required this.appConf,
  });
}
