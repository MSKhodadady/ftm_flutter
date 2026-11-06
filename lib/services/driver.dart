import 'dart:io';
import 'package:ftm_flutter/models/driver.dart';

class DriverService {
  Iterable<File> getAllFiles(Driver driver) {
    final filesDir = Directory(driver.path);
    final files = filesDir.listSync().whereType<File>();
    return files;
  }
}
