import 'package:ftm_flutter/data/file_item.dart';
import 'package:get/get.dart';

class SelectedFilesController extends GetxController {
  List<FileItem> selectedFiles = [];

  static SelectedFilesController get to => Get.find();

  void add(List<FileItem> fileItems) {
    selectedFiles = [...selectedFiles, ...fileItems];

    update();
  }

  void set(List<FileItem> fileItems) {
    selectedFiles = fileItems;

    update();
  }
}
