import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ftm_flutter/controllers/route.dart';
import 'package:ftm_flutter/controllers/selected_files.dart';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:ftm_flutter/files.dart';
import 'package:ftm_flutter/widget/file_leading.dart';
import 'package:path/path.dart';
import 'package:tuple/tuple.dart';

class SelectFile extends StatefulWidget {
  const SelectFile({super.key});

  @override
  State<SelectFile> createState() => _SelectFileState();
}

class _SelectFileState extends State<SelectFile> {
  String currentPath = homePath();
  bool multipleSelect = false;

  List<String> selectedFilesPath = [];

  Future<void> doneSelection(BuildContext context) async {
    final status = await checkAllFilesExist(
      selectedFilesPath.map(
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
    final d = Directory(currentPath);

    var fl = d
        .listSync()
        .where((element) => !basename(element.path).startsWith('.'));

    if (currentPath == homePath()) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("SelectFiles"),
        actions: appBarActions(context, filesList),
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
              trailing: multipleSelect && isFile(filesList[index].path)
                  ? Checkbox(
                      value: selectedFilesPath.contains(filesList[index].path),
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
                  setState(() {
                    currentPath = filesList[index].path;
                  });
                } else if (multipleSelect) {
                  if (selectedFilesPath.contains(p)) {
                    removeFromSelectedFiles(p);
                  } else {
                    addToSelectedFiles(p);
                  }
                } else {
                  addToSelectedFiles(p);
                  doneSelection(context);
                }
              },
              onLongPress: () {
                if (isFile(filesList[index].path)) {
                  setState(() {
                    multipleSelect = true;
                    selectedFilesPath = selectedFilesPath = [
                      ...selectedFilesPath,
                      filesList[index].path
                    ];
                  });
                }
              },
            ));
          })),
    );
  }

  void addToSelectedFiles(String path) {
    setState(() {
      selectedFilesPath = selectedFilesPath = [...selectedFilesPath, path];
    });
  }

  void removeFromSelectedFiles(String path) {
    setState(() {
      selectedFilesPath =
          selectedFilesPath.where((element) => element != path).toList();
      if (selectedFilesPath.isEmpty) {
        multipleSelect = false;
      }
    });
  }

  List<Widget> appBarActions(
      BuildContext context, List<FileSystemEntity> filesList) {
    List<Widget> res = [];

    if (multipleSelect) {
      res = [
        ...res,
        TextButton(
          onPressed: () {
            if (allSelected(
                filesList.where((element) => isFile(element.path)).toList())) {
              setState(() {
                selectedFilesPath = [];
                multipleSelect = false;
              });
            } else {
              setState(() {
                selectedFilesPath = filesList
                    .where((element) => isFile(element.path))
                    .map((e) => e.path)
                    .toList();
              });
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
            doneSelection(context);
          },
          child: const Text("Done"),
        ),
      ];
    }
    if (!(multipleSelect || currentPath == homePath())) {
      res = [
        ...res,
        TextButton(
            onPressed: (() {
              final d = Directory(currentPath);
              setState(() {
                currentPath = d.parent.path;
              });
            }),
            child: const Text(
              "Go Up",
            ))
      ];
    }

    return res;
  }

  bool allSelected(List<FileSystemEntity> fs) => fs
      .map((e) => e.path)
      .every((element) => selectedFilesPath.contains(element));
}

bool isFile(String path) => FileSystemEntity.isFileSync(path);
bool isDir(String path) => FileSystemEntity.isDirectorySync(path);
