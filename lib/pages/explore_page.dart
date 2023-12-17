import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:ftm_flutter/files.dart';
import 'package:ftm_flutter/widget/edit_file_tag.dart';
import 'package:ftm_flutter/widget/tag_autocomplete.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path/path.dart';

bool integrityChecked = false;

class ExplorePage extends HookWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final chosenTags = useState<List<String>>([]);
    final refreshKey = useState(UniqueKey());
    final fileTagMemo = useMemoized(() => filesListTagFilter_(chosenTags.value),
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
        onPressed: () {
          fullRefresh();
        },
        mini: true,
        child: const Icon(Icons.refresh),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            //: tag chooser
            TagAutocomplete(
                onSubmitted: (tag) {
                  chosenTags.value = [...chosenTags.value, tag];
                },
                chosenTags: chosenTags.value),
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
                ? Column(
                    children: (fileTagsFuture.data as Iterable<FileTag>)
                        .map((e) => ListTile(
                              title: Text(e.fileName),
                              leading: IconButton(
                                icon: const Icon(Icons.feed_outlined, size: 30),
                                onPressed: () {
                                  OpenFile.open(join(filesPath(), e.fileName));
                                },
                              ),
                              subtitle: Wrap(
                                children: e.tags
                                    .map((t) => Chip(
                                          label: Text(t),
                                          visualDensity: const VisualDensity(
                                              horizontal: 1, vertical: -4),
                                        ))
                                    .toList(),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () async {
                                  // TODO
                                  var k = await showDialog<ActionResult>(
                                      context: context,
                                      builder: (context) {
                                        return EditFileTag(oldFileTag: e);
                                      });
                                  if (k is Changed || k is Deleted) {
                                    refresh();
                                  }
                                },
                              ),
                            ))
                        .toList(),
                  )
                : const Text("No Data"),
          ],
        ),
      ),
    );
  }
}
