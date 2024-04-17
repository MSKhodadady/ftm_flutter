import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:ftm_flutter/files.dart';
import 'package:ftm_flutter/widget/edit_file_tag.dart';
import 'package:ftm_flutter/widget/file_tag_row.dart';
import 'package:ftm_flutter/widget/tag_autocomplete.dart';
import 'package:path/path.dart';

bool integrityChecked = false;

class ExplorePage extends HookWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final chosenTags = useState<List<String>>([]);
    final refreshKey = useState(UniqueKey());
    //: returns a cached value of returned value of a function
    final fileTagMemo = useMemoized(() => getFilesList(chosenTags.value),
        [refreshKey.value, chosenTags.value]);
    final fileTagsFuture = useFuture(fileTagMemo);

    void refresh() {
      refreshKey.value = UniqueKey();
    }

    void fullRefresh() {
      final integrityRes = checkIntegrity();

      integrityRes.then((res) {
        var snackText = "";

        if (res.filesToBeAddedToDb.isNotEmpty) {
          snackText =
              "${snackText}Some files added: ${res.filesToBeAddedToDb.toList().join(" ,")}";
        }

        if (res.dbItemsToBeRemoved.isNotEmpty) {
          snackText =
              "${snackText == '' ? '' : "$snackText\n"}Some Items deleted because of missing file: ${res.dbItemsToBeRemoved.toList().join(" ,")}";
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
      body: ListView(
        children: [
          //: tag chooser
          Container(
            padding: const EdgeInsets.all(10),
            child: TagAutocomplete(
                onSubmitted: (tag) {
                  chosenTags.value = [...chosenTags.value, tag];
                },
                chosenTags: chosenTags.value),
          ),
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
                              onFileAction: (k) async {
                                if (k is Changed) {
                                  await changeFile(e, k.newFileTag);
                                  refresh();
                                } else if (k is Deleted) {
                                  deleteFile(e);
                                  refresh();
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
