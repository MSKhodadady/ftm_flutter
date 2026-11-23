import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:ftm_flutter/models/file_tag.dart';

class SelectedFilesState extends ChangeNotifier {
  List<FileTag> selectedFiles = [];

  SelectedFilesState();

  void add(List<FileTag> fileItems) {
    final newList = [...selectedFiles, ...fileItems];

    selectedFiles = newList.fold<List<FileTag>>([], (previousValue, e1) {
      if (previousValue.any((e2) => e2.equals(e1))) {
        return previousValue;
      } else {
        return [...previousValue, e1];
      }
    });

    notifyListeners();
  }

  void addFilePick(List<PlatformFile> result) {
    selectedFiles.addAll(result
        .where((element) => element.path != null)
        .map((e) => FileTag(e.name, [], e.path ?? ""))
        .toList());

    notifyListeners();
  }

  void remove(FileTag fileTag) {
    selectedFiles = selectedFiles
        .where(
          (element) => !element.equals(fileTag),
        )
        .toList();

    notifyListeners();
  }

  void clear() {
    selectedFiles = [];

    notifyListeners();
  }

  void changeFile(FileTag oldFT, FileTag newFT) {
    selectedFiles = selectedFiles.map((e) {
      if (e.equals(oldFT)) {
        return newFT;
      } else {
        return e;
      }
    }).toList();

    notifyListeners();
  }
}
