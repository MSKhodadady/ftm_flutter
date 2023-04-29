import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ftm_flutter/data/file_item.dart';
import 'package:get/get.dart';

List<FileItem> selectedFilesState = [];

class SelectedFilesAction {
  final String type;
  final List<FileItem> files;

  const SelectedFilesAction(this.type, this.files);
}

Store<List<FileItem>, SelectedFilesAction>? _selectedFilesStore;

Store<List<FileItem>, SelectedFilesAction> useSelectedFilesReducer() {
  _selectedFilesStore ??= useReducer((state, action) {
    switch (action.type) {
      case 'init':
        return [];
      case 'set':
        return action.files;
      case 'add':
        return [...state, ...action.files];
      default:
        return state;
    }
  }, initialState: [], initialAction: const SelectedFilesAction('init', []));

  return _selectedFilesStore!;
}

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
