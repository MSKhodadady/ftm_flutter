import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:ftm_flutter/models/app_conf.dart';
import 'package:ftm_flutter/models/driver.dart';
import 'package:ftm_flutter/services/app_conf.dart';
import 'package:ftm_flutter/services/database.dart';
import 'package:ftm_flutter/services/driver.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:ftm_flutter/models/file_tag.dart';
import 'package:tuple/tuple.dart';

class DriverRepo {
  final DriverService _driverService;
  final AppConfService _appConfService;
  final DriverDbService _dbService;

  DriverRepo({
    required DriverService driverService,
    required AppConfService appConfService,
    required DriverDbService dbService,
  })  : _dbService = dbService,
        _appConfService = appConfService,
        _driverService = driverService;

  Future<DriverSyncResult> getCurrentDriver() async {
    //: read config from appConfService and initialize drivers
    AppConf mc = await _appConfService.readAppConf();

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

    final dataDir = Directory(p.join(currentDriver.path, mainDbFolder));
    if (!dataDir.existsSync()) {
      await dataDir.create(recursive: true);
    }

    final dbPath = p.join(currentDriver.path, mainDbFileName);

    final currentDriverDB = await _dbService.initDB(dbPath);

    //: FIXME: sync not needed!
    //: check db -> files sync
    final dbItemsToBeRemoved =
        await _checkSyncDbToFiles(currentDriver, currentDriverDB);
    //: check files -> db sync
    final filesToBeAddedToDb =
        await _checkSyncFilesToDb(currentDriver, currentDriverDB);

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

  Future<Iterable<String>> _checkSyncDbToFiles(
      Driver driver, Database db) async {
    final files = await _driverService.getAllFiles(driver);
    final dbFiles = await _dbService.getAllItems(db);

    final dbItemsToBeRemoved = dbFiles
        .where((dbFile) => !files.any((e) => p.basename(e.path) == dbFile));

    for (var e in dbItemsToBeRemoved) {
      _dbService.deleteFileTag(e, db);
    }

    return dbItemsToBeRemoved;
  }

  Future<Iterable<File>> _checkSyncFilesToDb(Driver driver, Database db) async {
    final files = await _driverService.getAllFiles(driver);

    bool checkNotExists(File file) {
      final fileName = p.basename(file.path);
      final exists = _dbService.findByFileName(fileName, db);

      return exists.isEmpty;
    }

    final filesToBeAddedToDb = files.where(checkNotExists);

    for (var file in filesToBeAddedToDb) {
      final ft = FileTag(p.basename(file.path), [], file.path);

      await _dbService.insertFT(ft, db);
    }
    return Future.value(filesToBeAddedToDb);
  }

  //: TODO: add pagination
  Future<List<FileTag>> getAllFiles({
    required DriverDatabase dd,
    List<String> includeTags = const [],
    List<String> excludeTags = const [],
  }) async {
    final db = dd.db;
    final res = await _dbService.getFiles(
        db: db, excludeTags: excludeTags, includeTags: includeTags);

    return res.map((e) => FileTag.fromMap(e, dd.path)).toList();
  }

  Future<void> changeFileTags(
      Database db, FileTag ft, List<String> tags) async {
    await _dbService.changeFileTags(db, ft, tags);
  }

  Future<bool> fileExists(DriverDatabase dd, String fileName) async {
    return _driverService.checkFileExist(fileName, dd.path) &&
        _dbService.fileDbExists(dd.db, fileName);
  }

  Future<void> changeFile(
    DriverDatabase dd,
    FileTag oldFT,
    FileTag newFT,
  ) async {
    if (oldFT.fileName != newFT.fileName) {
      final exists = await fileExists(dd, newFT.fileName);
      if (!exists) {
        throw FileExistsException();
      } else {
        _driverService.renameFile(oldFT, newFT);
        _dbService.rename(dd.db, oldFT.fileName, newFT.fileName);
      }
    }

    if (!listEquals(newFT.tags, oldFT.tags)) {
      await changeFileTags(dd.db, newFT, newFT.tags);
    }
  }

  Future<void> insertFileTags(
      DriverDatabase dd, Iterable<FileTag> selectedFiles) async {
    var futures = selectedFiles.map((ft) async {
      await _driverService.moveFileToDriver(dd.path, ft);
      await _dbService.insertFileTagDb(dd.db, ft);
    });

    await Future.wait(futures);
  }

  Future<FileTagExistStatus> checkAllFilesExists(
    Driver d,
    Iterable<FileTag> files,
  ) async {
    final existsStatus = await Isolate.run(
      () => files.map(
        (e) => Tuple2(e, _driverService.checkFileExist(d.path, e.fileName)),
      ),
    );

    final res = existsStatus.fold<FileTagExistStatus>(
      const FileTagExistStatus(exists: [], notExists: []),
      (acc, i) => i.item2 ? acc.addExist(i.item1) : acc.addNotExist(i.item1),
    );

    return res;
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

class FileExistsException implements Exception {}
