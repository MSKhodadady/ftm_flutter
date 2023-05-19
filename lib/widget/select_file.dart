import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ftm_flutter/files.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path/path.dart';

class SelectFile extends StatefulWidget {
  const SelectFile({super.key, required this.doneSelection});

  final void Function(List<String> selectedFiles) doneSelection;

  @override
  State<SelectFile> createState() => _SelectFileState();
}

const homePath = "/sdcard";

class _SelectFileState extends State<SelectFile> {
  String currentPath = "/sdcard";
  bool multipleSelect = false;

  List<String> selectedFiles = [];

  @override
  Widget build(BuildContext context) {
    final d = Directory(currentPath);

    var fl = d
        .listSync()
        .where((element) => !basename(element.path).startsWith('.'));

    if (currentPath == homePath) {
      fl = fl.where((element) => basename(element.path) != mainFolderName);
    }

    final filesList = fl.toList();
    filesList.sort(((a, b) => a.path.compareTo(b.path)));

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
              leading: FileSystemEntity.isFileSync(filesList[index].path)
                  ? IconButton(
                      onPressed: () {
                        OpenFile.open(filesList[index].path);
                      },
                      icon: const Icon(Icons.feed_outlined))
                  : const Icon(Icons.folder),
              trailing: multipleSelect && isFile(filesList[index].path)
                  ? Checkbox(
                      value: selectedFiles.contains(filesList[index].path),
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
                if (isDir(filesList[index].path)) {
                  setState(() {
                    currentPath = filesList[index].path;
                  });
                } else if (multipleSelect) {
                  final p = filesList[index].path;
                  if (selectedFiles.contains(p)) {
                    removeFromSelectedFiles(p);
                  } else {
                    addToSelectedFiles(p);
                  }
                } else {
                  widget.doneSelection([filesList[index].path]);
                }
              },
              onLongPress: () {
                if (isFile(filesList[index].path)) {
                  setState(() {
                    multipleSelect = true;
                    selectedFiles = selectedFiles = [
                      ...selectedFiles,
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
      selectedFiles = selectedFiles = [...selectedFiles, path];
    });
  }

  void removeFromSelectedFiles(String path) {
    setState(() {
      selectedFiles =
          selectedFiles.where((element) => element != path).toList();
      if (selectedFiles.isEmpty) {
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
                selectedFiles = [];
                multipleSelect = false;
              });
            } else {
              setState(() {
                selectedFiles = filesList
                    .where((element) => isFile(element.path))
                    .map((e) => e.path)
                    .toList();
              });
            }
          },
          child: Text(
              allSelected(filesList
                      .where((element) => isFile(element.path))
                      .toList())
                  ? "UnSelect All"
                  : "Select All",
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        ),
        TextButton(
          onPressed: () {
            widget.doneSelection(selectedFiles);
          },
          child: Text(
            "Done",
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
      ];
    }
    if (!(multipleSelect || currentPath == homePath)) {
      res = [
        ...res,
        TextButton(
            onPressed: (() {
              final d = Directory(currentPath);
              setState(() {
                currentPath = d.parent.path;
              });
            }),
            child: Text(
              "Go Up",
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ))
      ];
    }

    return res;
  }

  bool allSelected(List<FileSystemEntity> fs) =>
      fs.map((e) => e.path).every((element) => selectedFiles.contains(element));
}

bool isFile(String path) => FileSystemEntity.isFileSync(path);
bool isDir(String path) => FileSystemEntity.isDirectorySync(path);
