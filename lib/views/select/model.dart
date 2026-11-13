import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ftm_flutter/controllers/selected_files.dart';
import 'package:ftm_flutter/models/file_tag.dart';
import 'package:ftm_flutter/repos/driver.dart';
import 'package:ftm_flutter/util/io.dart';
import 'package:path/path.dart';
import 'package:tuple/tuple.dart';

class SelectFileViewModel extends ChangeNotifier {
  final SelectedFilesState _selectedFilesState;
  final DriverRepo _driverRepo;

  SelectFileViewModel({
    required SelectedFilesState selectedFilesState,
    required DriverRepo driverRepo,
  })  : _driverRepo = driverRepo,
        _selectedFilesState = selectedFilesState;

  String _currentPath = getHomePath();
  String get currentPath => _currentPath;

  bool _multipleSelect = false;
  bool get multipleSelect => _multipleSelect;

  List<String> _selectedFilesPath = [];
  List<String> get selectedFilesPath => _selectedFilesPath;

  /// first value is for [currentPath]
  Tuple2<String, List<FileSystemEntity>>? _filesListCache;

  List<FileSystemEntity> get filesList {
    if (_filesListCache == null || _filesListCache?.item1 != currentPath) {
      Directory d = Directory(currentPath);

      var fl = d
          .listSync()
          .where((element) => !basename(element.path).startsWith('.'));

      //: TODO: filter every path that contains a driver
      var filesList = fl.toList();
      //: soft by name
      filesList.sort(((a, b) => a.path.compareTo(b.path)));

      var fileDirSeparated =
          filesList.fold<Tuple2<List<Directory>, List<File>>>(
        const Tuple2([], []),
        (acc, i) {
          if (i is File) {
            acc.item2.add(i);
          } else if (i is Directory) {
            acc.item1.add(i);
          }
          return acc;
        },
      );

      filesList = [...fileDirSeparated.item1, ...fileDirSeparated.item2];

      _filesListCache = Tuple2(currentPath, filesList);
    }

    return _filesListCache!.item2;
  }

  //: functions
  void addToSelectedFiles(String path) {
    _selectedFilesPath = [..._selectedFilesPath, path];

    notifyListeners();
  }

  void removeFromSelectedFiles(String f) {
    _selectedFilesPath = _selectedFilesPath
        .where(
          (element) => element != f,
        )
        .toList();

    if (_selectedFilesPath.isEmpty) {
      _multipleSelect = false;
    }

    notifyListeners();
  }

  Future<FileTagExistStatus> doneSelection() async {
    //: TODO: check files not in current driver

    final d = await _driverRepo.getCurrentDriver();

    final status = await _driverRepo.checkAllFilesExists(
      d.currentDriver,
      _selectedFilesPath.map(
        (e) => FileTag(basename(e), [], e),
      ),
    );

    _selectedFilesState.selectedFiles = status.notExists.toList();

    return status;
  }

  void switchMultipleSelect(int index) {
    _multipleSelect = true;
    _selectedFilesPath = [..._selectedFilesPath, filesList[index].path];

    notifyListeners();
  }

  bool get allFilesSelected => filesList
      .where((element) => isFile(element.path))
      .map((e) => e.path)
      .every((element) => _selectedFilesPath.contains(element));

  void selectAll() {
    if (allFilesSelected) {
      _selectedFilesPath = [];
      _multipleSelect = false;
    } else {
      _selectedFilesPath = filesList
          .where((element) => isFile(element.path))
          .map((e) => e.path)
          .toList();
    }
    notifyListeners();
  }

  void goUp() {
    final d = Directory(currentPath);
    _currentPath = d.parent.path;

    notifyListeners();
  }

  void setPath(String fp) {
    _currentPath = fp;

    notifyListeners();
  }
}

bool isDir(String path) => FileSystemEntity.isDirectorySync(path);
bool isFile(String path) => FileSystemEntity.isFileSync(path);
