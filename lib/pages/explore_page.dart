import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:ftm_flutter/database.dart';
import 'package:ftm_flutter/files.dart';
import 'package:ftm_flutter/icon/zicon_outline_icons.dart';
import 'package:ftm_flutter/widget/add_tag_files.dart';
import 'package:ftm_flutter/widget/edit_file_tag.dart';
import 'package:ftm_flutter/widget/file_tag_row.dart';
import 'package:ftm_flutter/widget/tag_autocomplete.dart';
import 'package:ftm_flutter/widget/yes_no_dialog.dart';
import 'package:path/path.dart';

bool integrityChecked = false;

class ExplorePage extends HookWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final chosenTags = useState<List<String>>([]);
    final refreshKey = useState(UniqueKey());
    //: returns a cached value of returned value of a function
    final fileTagMemo = useMemoized(
        () => getFilesList(
              includeTags: chosenTags.value,
              excludeTags: [trashTag],
            ),
        [refreshKey.value, chosenTags.value]);
    final fileTagsFuture = useFuture(fileTagMemo);

    final selectedFiles = useState<List<FileTag>>([]);

    void refresh() {
      //: sets a new key for refresh key,
      //: causes fileTagMemo to function
      refreshKey.value = UniqueKey();
    }

    void fullRefresh() {
      final integrityRes = checkIntegrity();

      integrityRes.then((res) {
        var snackText = "";

        if (res.filesToBeAddedToDb.isNotEmpty) {
          // ignore: prefer_interpolation_to_compose_strings
          snackText = snackText +
              "Some files added: " +
              res.filesToBeAddedToDb.toList().join(" ,");
        }

        if (res.dbItemsToBeRemoved.isNotEmpty) {
          // ignore: prefer_interpolation_to_compose_strings
          snackText = (snackText == '' ? '' : "$snackText\n") +
              "Some Items deleted because of missing file: " +
              res.dbItemsToBeRemoved.toList().join(" ,");
        }

        if (snackText != '') {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(snackText)));
        }

        refresh();
      });
    }

    if (!integrityChecked) {
      fullRefresh();
      integrityChecked = true;
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          fullRefresh();
        },
        mini: true,
        child: const Icon(Icons.refresh),
      ),
      appBar: selectedFiles.value.isEmpty
          ? null
          : AppBar(
              leadingWidth: 200,
              leading: Container(
                margin: const EdgeInsets.only(left: 5),
                child: Row(
                  children: [
                    TextButton(
                        onPressed: () {
                          if (selectedFiles.value.length !=
                              (fileTagsFuture.data ?? []).length) {
                            selectedFiles.value = fileTagsFuture.data ?? [];
                          } else {
                            selectedFiles.value = [];
                          }
                        },
                        child: Text(selectedFiles.value.length !=
                                (fileTagsFuture.data ?? []).length
                            ? "Select All"
                            : "Deselect All")),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () async {
                      final newTags = await showDialog<List<String>>(
                        context: context,
                        builder: (context) => const AddTagFiles(),
                      );

                      if (newTags != null && newTags.isNotEmpty) {
                        await Future.wait(
                          selectedFiles.value.map((e) async {
                            await changeFileTags(
                              e,
                              [
                                ...{...e.tags, ...newTags}
                              ],
                            );
                          }),
                        );

                        selectedFiles.value = [];

                        refresh();
                      }
                    },
                    child: const Text("Add Tag")),
                TextButton(
                    onPressed: () async {
                      final res = await showDialog<bool?>(
                          context: context,
                          builder: (context) => const YesNoDialog(
                                quest: "Move to Trash?",
                              ));

                      if (res == true) {
                        Future.wait(
                          selectedFiles.value.map((e) async {
                            await changeFileTags(e, [...e.tags, trashTag]);
                          }),
                        );

                        selectedFiles.value = [];

                        refresh();
                      }
                    },
                    child: const Text("Trash")),
              ],
            ),
      body: ListView(
        children: [
          //: tag chooser
          selectedFiles.value.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(10),
                  child: TagAutocomplete(
                      onSubmitted: (tag) {
                        chosenTags.value = [...chosenTags.value, tag];
                      },
                      chosenTags: chosenTags.value),
                )
              : const SizedBox.shrink(),
          //: chosen tags
          AnimatedSize(
            duration: const Duration(milliseconds: 500),
            child: SizedBox(
              height: chosenTags.value.isEmpty ? 0 : 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: chosenTags.value
                    .map((e) => Container(
                          padding: const EdgeInsets.only(left: 5),
                          child: Chip(
                            label: Text(e),
                            color: MaterialStatePropertyAll(
                                Theme.of(context).colorScheme.secondary),
                            side: const BorderSide(color: Colors.transparent),
                            onDeleted: () {
                              chosenTags.value = chosenTags.value
                                  .where((element) => element != e)
                                  .toList();
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          //: fileTags
          fileTagsFuture.hasData
              ? Container(
                  margin: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    children: (fileTagsFuture.data as Iterable<FileTag>)
                        .map((e) => FileTagRow(
                              ft: e,
                              filePath: join(
                                filesPath(),
                                e.fileName,
                              ),
                              onTagClick: (tag) {
                                chosenTags.value = [...chosenTags.value, tag];
                              },
                              actions: [
                                IconButton(
                                  icon: const Icon(ZiconOutline.pen),
                                  onPressed: () async {
                                    var k = await showDialog<ActionResult>(
                                        context: context,
                                        builder: (context) {
                                          return EditFileTag(
                                            oldFileTag: e,
                                            isImport: false,
                                          );
                                        });

                                    if (k is Changed) {
                                      await changeFile(e, k.newFileTag);
                                      refresh();
                                    }
                                  },
                                )
                              ],
                              isSelected: selectedFiles.value.isEmpty
                                  ? null
                                  : selectedFiles.value
                                      .any((element) => element.equals(e)),
                              onSelect: (isAdded) {
                                if (isAdded != null && isAdded) {
                                  selectedFiles.value = [
                                    ...selectedFiles.value,
                                    e
                                  ];
                                } else {
                                  selectedFiles.value = selectedFiles.value
                                      .where((element) => !element.equals(e))
                                      .toList();
                                }
                              },
                            ))
                        .toList(),
                  ),
                )
              : const Text("No Data"),
        ],
      ),
    );
  }
}
