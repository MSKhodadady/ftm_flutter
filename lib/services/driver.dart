import 'dart:io';
import 'package:ftm_flutter/models/driver.dart';

class DriverService {
  Future<Iterable<File>> getAllFiles(Driver driver) async {
    final filesDir = Directory(driver.path);
    final files = await filesDir.list().toList();
    return files.whereType<File>();
  }
}
