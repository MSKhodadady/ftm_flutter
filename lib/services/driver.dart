import 'dart:io';
import 'package:ftm_flutter/models/driver.dart';
import 'package:ftm_flutter/models/file_tag.dart';
import 'package:path/path.dart' as p;

class DriverService {
  Future<Iterable<File>> getAllFiles(Driver driver) async {
    final filesDir = Directory(driver.path);
    final files = await filesDir.list().toList();
    return files.whereType<File>();
  }

  bool checkFileExist(String fileName, String driverPath) {
    final fileExists = File(p.join(driverPath, fileName)).existsSync();

    return fileExists;
  }

  Future<void> renameFile(FileTag oldFT, FileTag newFT) async {
    var f = File(oldFT.path);
    await f.rename(newFT.path);
  }

  Future<void> moveFileToDriver(String driverPath, FileTag ft) async {
    //: move or copy file
    var f = File(ft.path);
    // TODO: copy or move by config, move by default
    await f.copy(p.join(driverPath, ft.fileName));
    await f.delete();
  }
}
