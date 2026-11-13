import 'dart:io';
import 'package:ftm_flutter/util/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ftm_flutter/icon/zicon_outline_icons.dart';
import 'package:ftm_flutter/views/select/model.dart';
import 'package:ftm_flutter/widget/file_leading.dart';
import 'package:path/path.dart';

class SelectFileView extends HookWidget {
  final SelectFileViewModel vm;
  const SelectFileView({
    super.key,
    required this.vm,
  });

  Future<void> doneSelection(BuildContext context) async {
    if (vm.selectedFilesPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("no file selected"),
        ),
      );

      return;
    }

    final status = await vm.doneSelection();

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

    // ignore: use_build_context_synchronously
    Navigator.pushNamed(context, '/add');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, child) => Scaffold(
        appBar: AppBar(
          title: const Text("SelectFiles"),
          actions: appBarActions(context),
          leading: IconButton(
            icon: const Icon(ZiconOutline.back_1),
            onPressed: () {
              Navigator.pushNamed(context, '/explore');
            },
          ),
        ),
        body: ListView.builder(
            itemCount: vm.filesList.length,
            itemBuilder: ((context, index) {
              var fp = vm.filesList[index].path;

              return Card(
                  child: ListTile(
                leading: SizedBox(
                  width: 100,
                  child: FileLeading(filePath: fp),
                ),
                trailing: vm.multipleSelect && isFile(fp)
                    ? Checkbox(
                        value: vm.selectedFilesPath.contains(fp),
                        onChanged: (newValue) {
                          final p = fp;
                          if (newValue != null && isFile(p)) {
                            if (newValue) {
                              vm.addToSelectedFiles(p);
                            } else {
                              vm.removeFromSelectedFiles(p);
                            }
                          }
                        },
                      )
                    : null,
                title: Text(basename(fp)),
                onTap: () {
                  final p = fp;

                  if (isDir(fp)) {
                    vm.setPath(fp);
                  } else if (vm.multipleSelect) {
                    if (vm.selectedFilesPath.contains(p)) {
                      vm.removeFromSelectedFiles(p);
                    } else {
                      vm.addToSelectedFiles(p);
                    }
                  } else {
                    vm.addToSelectedFiles(p);
                    doneSelection(context);
                  }
                },
                onLongPress: () {
                  if (isFile(fp)) {
                    vm.switchMultipleSelect(index);
                  }
                },
              ));
            })),
      ),
    );
  }

  List<Widget> appBarActions(
    BuildContext context,
  ) {
    List<Widget> res = [];

    if (vm.multipleSelect) {
      res.addAll([
        TextButton(
          onPressed: () => vm.selectAll(),
          child: Text(
            vm.allFilesSelected ? "UnSelect All" : "Select All",
          ),
        ),
        TextButton(
          onPressed: () {
            doneSelection(context);
          },
          child: const Text("Done"),
        ),
      ]);
    }

    if (!(vm.multipleSelect || vm.currentPath == getHomePath())) {
      res.add(TextButton(
        onPressed: () => vm.goUp(),
        child: const Text(
          "Go Up",
        ),
      ));
    }

    return res;
  }
}

bool isFile(String path) => FileSystemEntity.isFileSync(path);

bool isDir(String path) => FileSystemEntity.isDirectorySync(path);
