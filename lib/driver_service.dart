import 'dart:io';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:ftm_flutter/db_service.dart';
import 'package:ftm_flutter/main_conf_repo.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

const _mainDbFileName = 'ftm.db';
const _mainDbFolder = 'data';

class Driver {
  final String name;
  final String path;
  final String type;

  Driver({
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

  DriverDatabase({
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

  DriverSyncResult({
    required this.currentDriver,
    required this.dbItemsToBeRemoved,
    required this.filesToBeAddedToDb,
    required this.appConf,
  });
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

  Future<DriverSyncResult> getCurrentDriver() async {
    //: read config from appConfService and initialize drivers
    AppConf mc = await appConfService.readAppConf();

    //: init current driver from driverService
    final cd = mc.drivers.firstWhereOrNull((e) => e.name == mc.currentDriver);
    assert(cd != null,
        'current driver must not be null and must be in the drivers list');
    Driver currentDriver = cd!;

    final dir = Directory(currentDriver.path);

    if (!dir.existsSync()) {
      try {
        //: try to create the directory if it does not exist
        await dir.create(recursive: true);
      } catch (e) {
        throw CannotCreateDriverDirException(
          innerException: e,
          driver: currentDriver,
          message: 'Cannot create driver directory: ${currentDriver.path}',
        );
      }
    }

    final dataDir = Directory(p.join(currentDriver.path, _mainDbFolder));
    if (!dataDir.existsSync()) {
      await dataDir.create(recursive: true);
    }

    final dbPath = p.join(currentDriver.path, _mainDbFileName);

    final currentDriverDB = await dbService.initDB(dbPath);

    //: check db -> files sync
    final dbItemsToBeRemoved =
        await checkSyncDbToFiles(currentDriver, currentDriverDB);

    //: check files -> db sync
    final filesToBeAddedToDb =
        await checkSyncFilesToDb(currentDriver, currentDriverDB);

    return DriverSyncResult(
      currentDriver: DriverDatabase(
        name: currentDriver.name,
        path: currentDriver.path,
        type: currentDriver.type,
        db: currentDriverDB,
      ),
      dbItemsToBeRemoved: dbItemsToBeRemoved,
      filesToBeAddedToDb: filesToBeAddedToDb,
      appConf: mc,
    );
  }

  Future<Iterable<String>> checkSyncDbToFiles(Driver driver, Database db) {
    // TODO: futurize it!
    final files = driverService.getAllFiles(driver);
    final dbFiles = dbService.getAllItems(db);

    final dbItemsToBeRemoved = dbFiles
        .where((dbFile) => !files.any((e) => p.basename(e.path) == dbFile));

    for (var e in dbItemsToBeRemoved) {
      dbService.deleteFileTag(e, db);
    }

    return Future.value(dbItemsToBeRemoved);
  }

  Future<Iterable<File>> checkSyncFilesToDb(Driver driver, Database db) {
    // TODO: futurize it!
    final files = driverService.getAllFiles(driver);

    bool checkNotExists(File file) {
      final fileName = p.basename(file.path);
      final exists = dbService.findByFileName(fileName, db);

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
  Iterable<File> getAllFiles(Driver driver) {
    final filesDir = Directory(driver.path);
    final files = filesDir.listSync().whereType<File>();
    return files;
  }
}

class CannotCreateDriverDirException implements Exception {
  final String message;
  final Driver driver;
  final Object innerException;
  CannotCreateDriverDirException(
      {required this.driver,
      required this.message,
      required this.innerException});

  @override
  String toString() =>
      'CannotCreateDriverDirException: $message - Driver: ${driver.name} at ${driver.path}';
}
