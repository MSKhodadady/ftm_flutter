import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ftm_flutter/controllers/route.dart';
import 'package:ftm_flutter/controllers/selected_files.dart';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:ftm_flutter/files.dart';
import 'package:ftm_flutter/icon/zicon_outline_icons.dart';
import 'package:ftm_flutter/widget/file_leading.dart';
import 'package:path/path.dart';
import 'package:tuple/tuple.dart';

class SelectFile extends HookWidget {
  const SelectFile({super.key});

  Future<void> doneSelection(
    BuildContext context,
    ValueNotifier<List<String>> selectedFilesPath,
  ) async {
    final status = await checkAllFilesExist(
      selectedFilesPath.value.map(
        (e) => FileTag(basename(e), [], e),
      ),
    );

    if (status.exists.isNotEmpty) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${status.exists.length} file(s) exists: ${status.exists.map((e) => e.fileName).join(", ")}",
          ),
        ),
      );
    }

    SelectedFilesController.to.add(status.notExists.toList());

    RouteController.to.setRoute(RoutePages.addPage);
  }

  @override
  Widget build(BuildContext context) {
    //: state
    final currentPath = useState(homePath());
    final multipleSelect = useState(false);
    final selectedFilesPath = useState<List<String>>([]);

    //: prepare
    final d = Directory(currentPath.value);

    var fl = d
        .listSync()
        .where((element) => !basename(element.path).startsWith('.'));

    if (currentPath.value == homePath()) {
      fl = fl.where((element) => basename(element.path) != mainFolderName);
    }

    var filesList = fl.toList();
    filesList.sort(((a, b) => a.path.compareTo(b.path)));

    var separated = filesList.fold<Tuple2<List<Directory>, List<File>>>(
        const Tuple2([], []), (previousValue, element) {
      if (element is File) {
        return Tuple2(previousValue.item1, [...previousValue.item2, element]);
      } else if (element is Directory) {
        return Tuple2([...previousValue.item1, element], previousValue.item2);
      }
      return previousValue;
    });

    filesList = [...separated.item1.toList(), ...separated.item2.toList()];

    //: functions
    void addToSelectedFiles(String path) {
      selectedFilesPath.value = [...selectedFilesPath.value, path];
    }

    void removeFromSelectedFiles(String path) {
      selectedFilesPath.value =
          selectedFilesPath.value.where((element) => element != path).toList();
      if (selectedFilesPath.value.isEmpty) {
        multipleSelect.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("SelectFiles"),
        actions: appBarActions(
            context, filesList, multipleSelect, selectedFilesPath, currentPath),
        leading: IconButton(
          icon: const Icon(ZiconOutline.back_1),
          onPressed: () {
            RouteController.to.setRoute(RoutePages.explorePage);
          },
        ),
      ),
      body: ListView.builder(
          itemCount: filesList.length,
          itemBuilder: ((context, index) {
            return Card(
                child: ListTile(
              leading: SizedBox(
                width: 100,
                child: FileLeading(filePath: filesList[index].path),
              ),
              trailing: multipleSelect.value && isFile(filesList[index].path)
                  ? Checkbox(
                      value: selectedFilesPath.value
                          .contains(filesList[index].path),
                      onChanged: (newValue) {
                        final p = filesList[index].path;
                        if (newValue != null && isFile(p)) {
                          if (newValue) {
                            addToSelectedFiles(p);
                          } else {
                            removeFromSelectedFiles(p);
                          }
                        }
                      })
                  : null,
              title: Text(basename(filesList[index].path)),
              onTap: () {
                final p = filesList[index].path;

                if (isDir(filesList[index].path)) {
                  currentPath.value = filesList[index].path;
                } else if (multipleSelect.value) {
                  if (selectedFilesPath.value.contains(p)) {
                    removeFromSelectedFiles(p);
                  } else {
                    addToSelectedFiles(p);
                  }
                } else {
                  addToSelectedFiles(p);
                  doneSelection(context, selectedFilesPath);
                }
              },
              onLongPress: () {
                if (isFile(filesList[index].path)) {
                  multipleSelect.value = true;
                  selectedFilesPath.value = [
                    ...selectedFilesPath.value,
                    filesList[index].path
                  ];
                }
              },
            ));
          })),
    );
  }

  List<Widget> appBarActions(
    BuildContext context,
    List<FileSystemEntity> filesList,
    ValueNotifier<bool> multipleSelect,
    ValueNotifier<List<String>> selectedFilesPath,
    ValueNotifier<String> currentPath,
  ) {
    bool allSelected(List<FileSystemEntity> fs) => fs
        .map((e) => e.path)
        .every((element) => selectedFilesPath.value.contains(element));

    List<Widget> res = [];

    if (multipleSelect.value) {
      res = [
        ...res,
        TextButton(
          onPressed: () {
            if (allSelected(
                filesList.where((element) => isFile(element.path)).toList())) {
              selectedFilesPath.value = [];
              multipleSelect.value = false;
            } else {
              selectedFilesPath.value = filesList
                  .where((element) => isFile(element.path))
                  .map((e) => e.path)
                  .toList();
            }
          },
          child: Text(
            allSelected(
                    filesList.where((element) => isFile(element.path)).toList())
                ? "UnSelect All"
                : "Select All",
          ),
        ),
        TextButton(
          onPressed: () {
            doneSelection(context, selectedFilesPath);
          },
          child: const Text("Done"),
        ),
      ];
    }
    if (!(multipleSelect.value || currentPath.value == homePath())) {
      res = [
        ...res,
        TextButton(
            onPressed: (() {
              final d = Directory(currentPath.value);
              currentPath.value = d.parent.path;
            }),
            child: const Text(
              "Go Up",
            ))
      ];
    }

    return res;
  }
}

bool isFile(String path) => FileSystemEntity.isFileSync(path);
bool isDir(String path) => FileSystemEntity.isDirectorySync(path);
