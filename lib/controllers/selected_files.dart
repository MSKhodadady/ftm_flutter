import 'package:ftm_flutter/data/file_tag.dart';
import 'package:get/get.dart';

class SelectedFilesController extends GetxController {
  List<FileTag> selectedFiles = [];

  static SelectedFilesController get to => Get.find();

  void add(List<FileTag> fileItems) {
    final newList = [...selectedFiles, ...fileItems];

    selectedFiles = newList.fold<List<FileTag>>([], (previousValue, e1) {
      if (previousValue.any((e2) => e2.equals(e1))) {
        return previousValue;
      } else {
        return [...previousValue, e1];
      }
    });

    update();
  }

  void remove(FileTag fileTag) {
    selectedFiles = selectedFiles
        .where(
          (element) => !element.equals(fileTag),
        )
        .toList();

    update();
  }

  void clear() {
    selectedFiles = [];

    update();
  }

  void changeFile(FileTag oldFT, FileTag newFT) {
    selectedFiles = selectedFiles.map((e) {
      if (e.equals(oldFT)) {
        return newFT;
      } else {
        return e;
      }
    }).toList();

    update();
  }
}
