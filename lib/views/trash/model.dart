import 'package:flutter/foundation.dart';
import 'package:ftm_flutter/models/driver.dart';
import 'package:ftm_flutter/models/file_tag.dart';
import 'package:ftm_flutter/repos/driver.dart';

class TrashViewModel extends ChangeNotifier {
  final DriverRepo _driverRepo;

  TrashViewModel({required DriverRepo driverRepo}) : _driverRepo = driverRepo;

  List<FileTag>? _files;
  List<FileTag>? get files => _files;

  DriverDatabase? _driverDatabase;

  List<FileTag> _selectedFiles = [];
  List<FileTag> get selectedFiles => _selectedFiles;

  Future<DriverDatabase> init() async {
    if (_driverDatabase == null) {
      final res = await _driverRepo.getCurrentDriver();
      _driverDatabase = res.currentDriver;
      return res.currentDriver;
    } else {
      return _driverDatabase!;
    }
  }

  Future<void> getFilesList() async {
    var dd = await init();

    _files = await _driverRepo.getAllFiles(
      dd: dd,
      includeTags: [FileTag.trashTag],
    );

    notifyListeners();
  }

  Future<void> deleteAllOrSelectedFiles() async {
    var dd = await init();

    if (selectedFiles.isEmpty && _files != null) {
      var futures = _files!.map((e) => _driverRepo.deleteFile(dd, e));
      await Future.wait(futures);
    } else {
      var futures = selectedFiles.map((e) => _driverRepo.deleteFile(dd, e));
      await Future.wait(futures);
    }

    _selectedFiles = [];

    await getFilesList();
  }

  Future<void> restoreAllOrSelected() async {
    var dd = await init();

    if (selectedFiles.isEmpty && _files != null) {
      var futures = _files!.map((e) => _driverRepo.restoreFile(dd, e));
      await Future.wait(futures);
    } else {
      var futures = selectedFiles.map((e) => _driverRepo.restoreFile(dd, e));
      await Future.wait(futures);
    }

    _selectedFiles = [];
    getFilesList();
  }

  void addRemoveSelectedFile(bool? isAdded, FileTag e) {
    if (isAdded != null && isAdded) {
      _selectedFiles.add(e);
    } else {
      _selectedFiles =
          selectedFiles.where((element) => !element.equals(e)).toList();
    }

    notifyListeners();
  }

  Future<void> deleteFileTag(FileTag e) async {
    var dd = await init();
    await _driverRepo.deleteFile(dd, e);

    await getFilesList();
  }

  Future<void> restoreFileTag(FileTag e) async {
    var dd = await init();
    await _driverRepo.restoreFile(dd, e);

    await getFilesList();
  }
}
