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
}
