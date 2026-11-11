import 'package:flutter/foundation.dart';
import 'package:ftm_flutter/controllers/selected_files.dart';
import 'package:ftm_flutter/models/driver.dart';
import 'package:ftm_flutter/models/file_tag.dart';
import 'package:ftm_flutter/repos/driver.dart';

class AddViewModel extends ChangeNotifier {
  SelectedFilesState selectedFilesState;
  DriverRepo driverRepo;

  AddViewModel({required this.selectedFilesState, required this.driverRepo});

  List<String> _chosenTags = [];
  List<String> get chosenTags => _chosenTags;
  DriverDatabase? _dd;
  List<FileTag> get selectedFiles => selectedFilesState.selectedFiles;

  Future<DriverDatabase> _getDriverDatabase() async {
    if (_dd == null) {
      var res = await driverRepo.getCurrentDriver();

      _dd = res.currentDriver;
    }

    return _dd!;
  }

  Future<void> onPressAdd() async {
    final dd = await _getDriverDatabase();

    final fts = selectedFilesState.selectedFiles.map(
      (e) => FileTag(
        e.fileName,
        {...e.tags, ...chosenTags}.toList(),
        e.path,
      ),
    );

    await driverRepo.insertFileTags(dd, fts);
  }

  void addChosenTag(String e) {
    _chosenTags.add(e);

    notifyListeners();
  }

  void removeChosenTag(String e) {
    _chosenTags = _chosenTags.where((element) => element != e).toList();

    notifyListeners();
  }

  void changeSelectedFile(FileTag oldFT, FileTag newFT) {
    selectedFilesState.changeFile(oldFT, newFT);
  }

  void removeSelectedFile(FileTag e) {
    selectedFilesState.remove(e);
  }
}
