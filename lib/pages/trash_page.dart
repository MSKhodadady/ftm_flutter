import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:ftm_flutter/database.dart';
import 'package:ftm_flutter/hooks/loading.dart';
import 'package:ftm_flutter/icon/zicon_outline_icons.dart';
import 'package:ftm_flutter/widget/file_tag_row.dart';
import 'package:ftm_flutter/widget/yes_no_dialog.dart';

class TrashPage extends HookWidget {
  const TrashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final refreshKey = useState(UniqueKey());
    //: returns a cached value of returned value of a function
    final fileTagMemo = useMemoized(
        () => getFilesList(includeTags: [trashTag]), [refreshKey.value]);
    final fileTagsFuture = useFuture(fileTagMemo);
    final selectedFiles = useState<List<FileTag>>([]);

    final loadingHook = LoadingHook();

    void refresh() {
      refreshKey.value = UniqueKey();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trash"),
        actions: [
          ButtonBar(
            children: [
              TextButton(
                  onPressed: () async {
                    final k = await showDialog<bool?>(
                        context: context,
                        builder: (context) {
                          return const YesNoDialog();
                        });

                    if (k == true) {
                      loadingHook.withLoading(() async {
                        if (selectedFiles.value.isEmpty &&
                            fileTagsFuture.hasData) {
                          for (var element in fileTagsFuture.data!) {
                            deleteFile(element);
                          }
                        } else {
                          for (var element in selectedFiles.value) {
                            deleteFile(element);
                          }
                        }

                        selectedFiles.value = [];
                        refresh();
                      });
                    }
                  },
                  child: Text(
                    selectedFiles.value.isEmpty ? "Delete All" : "Delete",
                  )),
              TextButton(
                  onPressed: () {
                    loadingHook.withLoading(() async {
                      if (selectedFiles.value.isEmpty &&
                          fileTagsFuture.hasData) {
                        for (var element in fileTagsFuture.data!) {
                          restoreTrashFile(element);
                        }
                      } else {
                        for (var element in selectedFiles.value) {
                          restoreTrashFile(element);
                        }
                      }

                      selectedFiles.value = [];
                      refresh();
                    });
                  },
                  child: Text(
                    selectedFiles.value.isEmpty ? "Restore All" : "Restore",
                  ))
            ],
          )
        ],
      ),
      body: ListView(children: [
        fileTagsFuture.hasData && !loadingHook.isLoading.value
            ? Column(
                children: fileTagsFuture.data!
                    .map((e) => FileTagRow(
                          ft: e,
                          filePath: e.path,
                          isSelected: selectedFiles.value.isEmpty
                              ? null
                              : selectedFiles.value.contains(e),
                          onSelect: (isAdded) {
                            if (isAdded != null && isAdded) {
                              selectedFiles.value = [...selectedFiles.value, e];
                            } else {
                              selectedFiles.value = selectedFiles.value
                                  .where((element) => !element.equals(e))
                                  .toList();
                            }
                          },
                          actions: [
                            IconButton(
                                onPressed: () async {
                                  final bool? k = await showDialog(
                                      context: context,
                                      builder: (c) {
                                        return const YesNoDialog();
                                      });

                                  if (k == true) {
                                    deleteFile(e);
                                    refresh();
                                  }
                                },
                                icon: const Icon(ZiconOutline.trash)),
                            IconButton(
                                onPressed: () {
                                  restoreTrashFile(e);

                                  refresh();
                                },
                                icon: const Icon(ZiconOutline.replay))
                          ],
                        ))
                    .toList(),
              )
            : Container(
                margin: const EdgeInsets.only(top: 20),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                  ],
                ),
              )
      ]),
    );
  }
}
