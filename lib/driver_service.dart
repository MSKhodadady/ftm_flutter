import 'dart:io';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:ftm_flutter/db_service.dart';
import 'package:ftm_flutter/main_conf_repo.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

const _mainDbFileName = 'ftm.db';

class Driver {
  final String name;
  final String path;
  final String type;

  Driver._raw({
    required this.name,
    required this.path,
    required this.type,
  });

  factory Driver.fromMap(Map<String, dynamic> m) {
    final name = m['name'], path = m['path'], type = m['type'];
    final correct = name is String && path is String && type is String;

    assert(correct, 'driver map is not correct');

    return Driver._raw(
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

class DriverRepo {
  DriverService driverService;
  AppConfService appConfService;
  DriverDbService dbService;

  DriverRepo(
    this.driverService,
    this.appConfService,
    this.dbService,
  );

  Future<Driver> getCurrentDriver() async {
    //: read config from appConfService and initialize drivers
    final mc = await appConfService.readAppConf();

    //: init current driver from driverService
    final cd = mc.drivers.firstWhereOrNull((e) => e.name == mc.currentDriver);
    assert(cd != null,
        'current driver must not be null and must be in the drivers list');
    Driver currentDriver = cd!;

    final res = await driverService.checkDriverDirExists(currentDriver);

    if (!res) {
      //: FIXME:
    }

    final dbPath = p.join(currentDriver.path, _mainDbFileName);

    final currentDriverDB = await dbService.initDB(dbPath);

    //: check db -> files sync
    final dbItemsToBeRemoved =
        await checkSyncDbToFiles(currentDriver, currentDriverDB);

    //: check files -> db sync
    final filesToBeAddedToDb =
        await checkSyncFilesToDb(currentDriver, currentDriverDB);

    return currentDriver;
  }

  Future<Iterable<String>> checkSyncDbToFiles(Driver driver, Database db) {
    final filesDir = Directory(driver.path);

    final files = filesDir.listSync().whereType<File>();

    final dbFiles = db
        .select("SELECT $fileNameColumn FROM $fileTagTable;")
        .map<String>((e) => e[fileNameColumn]);

    final dbItemsToBeRemoved = dbFiles
        .where((dbFile) => !files.any((e) => p.basename(e.path) == dbFile));

    for (var e in dbItemsToBeRemoved) {
      db.execute("DELETE FROM $fileTagTable WHERE $fileNameColumn = '$e';");
    }

    return Future.value(dbItemsToBeRemoved);
  }

  Future<Iterable<File>> checkSyncFilesToDb(Driver driver, Database db) {
    final filesDir = Directory(driver.path);

    final files = filesDir.listSync().whereType<File>();

    bool checkNotExists(File file) {
      final fileName = p.basename(file.path);
      final exists = db.select(
          "SELECT $fileNameColumn FROM $fileTagTable WHERE $fileNameColumn = ?1;",
          [fileName]);

      return exists.isEmpty;
    }

    final filesToBeAddedToDb = files.where(checkNotExists);

    for (var file in filesToBeAddedToDb) {
      final ft = FileTag(p.basename(file.path), [], file.path);

      dbService.insertFT(ft, db);
    }
    return Future.value(filesToBeAddedToDb);
  }
}

class DriverService {
  Future<bool> checkDriverDirExists(Driver driver) async {
    final dir = Directory(driver.path);
    return dir.exists();
  }
}
