import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:ftm_flutter/models/driver.dart';
import 'package:ftm_flutter/repos/driver.dart';

class ExploreViewModel extends ChangeNotifier {
  DriverRepo driverRepo;
  ExploreViewModel({
    required this.driverRepo,
  });

  DriverDatabase? _driverDatabase;

  List<FileTag>? _files; // null means not-loaded
  List<String> _chosenTags = [];
  List<FileTag> _selectedFiles = [];

  List<String> get chosenTags => _chosenTags;
  List<FileTag> get selectedFiles => _selectedFiles;
  List<FileTag>? get files => _files;

  Future<DriverDatabase> init() async {
    if (_driverDatabase == null) {
      final res = await driverRepo.getCurrentDriver();
      _driverDatabase = res.currentDriver;
      return res.currentDriver;
    } else {
      return _driverDatabase!;
    }
  }

  Future<void> getFilesList() async {
    var dd = (await init());

    _files = await driverRepo.getAllFiles(
      dd: dd,
      excludeTags: [FileTag.trashTag],
      includeTags: _chosenTags,
    );

    notifyListeners();
  }

  Future<void> fullRefresh() async {
    if (_driverDatabase != null) {
      _driverDatabase!.db.close();
      _driverDatabase = null;
    }

    getFilesList();
  }

  bool get allSelected => _selectedFiles.length != (_files ?? []).length;

  void selectDeselectAll() {
    if (allSelected && _files != null) {
      _selectedFiles = _files!;
    } else {
      _selectedFiles = [];
    }

    notifyListeners();
  }

  Future<void> addTags(List<String>? newTags) async {
    if (newTags != null && newTags.isNotEmpty) {
      await Future.wait(
        _selectedFiles.map((e) async {
          //: FIXME:
          await changeFileTags(
            e,
            [
              ...{...e.tags, ...newTags}
            ],
          );
        }),
      );

      _selectedFiles = [];

      getFilesList();

      notifyListeners();
    }
  }

  void moveToTrash() {
    Future.wait(
      _selectedFiles.map((e) async {
        //: FIXME:
        await changeFileTags(e, [...e.tags, FileTag.trashTag]);
      }),
    );

    _selectedFiles = [];

    getFilesList();

    notifyListeners();
  }

  void removeTag(String e) {
    _chosenTags = _chosenTags.where((element) => element != e).toList();

    getFilesList();

    notifyListeners();
  }

  void onAddTags(String tag) {
    _chosenTags = [..._chosenTags, tag];

    getFilesList();

    notifyListeners();
  }

  Future<void> changeTagsOfFile(FileTag oldFT, FileTag newFT) async {
    //: FIXME:
    await changeFile(oldFT, newFT);
    getFilesList();
    notifyListeners();
  }

  Future<void> onSelectFile(bool? isAdded, FileTag e) async {
    if (isAdded != null && isAdded) {
      _selectedFiles = [..._selectedFiles, e];
    } else {
      _selectedFiles =
          _selectedFiles.where((element) => !element.equals(e)).toList();
    }

    notifyListeners();
  }
}
