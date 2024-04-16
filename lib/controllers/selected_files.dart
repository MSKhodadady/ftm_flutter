import 'package:ftm_flutter/data/file_tag.dart';
import 'package:get/get.dart';

class SelectedFilesController extends GetxController {
  List<FileTag> selectedFiles = [];

  static SelectedFilesController get to => Get.find();

  void add(List<FileTag> fileItems) {
    selectedFiles = [...selectedFiles, ...fileItems];

    update();
  }

  void set(List<FileTag> fileItems) {
    selectedFiles = fileItems;

    update();
  }
}
