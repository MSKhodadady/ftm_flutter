import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ftm_flutter/icon/zicon_outline_icons.dart';
import 'package:ftm_flutter/views/explore/model.dart';
import 'package:ftm_flutter/widget/add_tag_files.dart';
import 'package:ftm_flutter/widget/edit_file_tag.dart';
import 'package:ftm_flutter/widget/file_tag_row.dart';
import 'package:ftm_flutter/widget/tag_autocomplete.dart';
import 'package:ftm_flutter/widget/yes_no_dialog.dart';

class ExploreView extends HookWidget {
  final ExploreViewModel exploreViewModel;

  const ExploreView({super.key, required this.exploreViewModel});

  @override
  Widget build(BuildContext context) {
    void fullRefresh() {
      exploreViewModel.fullRefresh();
    }

    if (!exploreViewModel.integrityChecked) {
      fullRefresh();
      exploreViewModel.integrityChecked = true;
    }

    return ListenableBuilder(
      listenable: exploreViewModel,
      builder: (context, child) => Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            fullRefresh();
          },
          mini: true,
          child: const Icon(Icons.refresh),
        ),
        appBar: exploreViewModel.selectedFiles.isEmpty
            ? null
            : AppBar(
                leadingWidth: 200,
                leading: Container(
                  margin: const EdgeInsets.only(left: 5),
                  child: Row(
                    children: [
                      TextButton(
                          onPressed: () => exploreViewModel.selectDeselectAll(),
                          child: Text(
                            exploreViewModel.allSelected
                                ? "Select All"
                                : "Deselect All",
                          )),
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

                      exploreViewModel.addTags(newTags);
                    },
                    child: const Text("Add Tag"),
                  ),
                  TextButton(
                    onPressed: () async {
                      final res = await showDialog<bool?>(
                        context: context,
                        builder: (context) =>
                            const YesNoDialog(quest: "Move to Trash?"),
                      );

                      if (res == true) {
                        exploreViewModel.moveToTrash();
                      }
                    },
                    child: const Text("Trash"),
                  )
                ],
              ),
        body: ListView(
          children: [
            //: tag chooser
            exploreViewModel.selectedFiles.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(10),
                    child: TagAutocomplete(
                      onSubmitted: (tag) {
                        exploreViewModel.onAddTags(tag);
                      },
                      chosenTags: exploreViewModel.chosenTags,
                    ),
                  )
                : const SizedBox.shrink(),
            //: chosen tags
            AnimatedSize(
              duration: const Duration(milliseconds: 500),
              child: SizedBox(
                height: exploreViewModel.chosenTags.isEmpty ? 0 : 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: exploreViewModel.chosenTags
                      .map(
                        (e) => Container(
                          padding: const EdgeInsets.only(left: 5),
                          child: Chip(
                            label: Text(e),
                            color: WidgetStatePropertyAll(
                                Theme.of(context).colorScheme.secondary),
                            side: const BorderSide(color: Colors.transparent),
                            onDeleted: () {
                              exploreViewModel.removeTag(e);
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            //: fileTags
            exploreViewModel.files != null
                ? Container(
                    margin: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      children: exploreViewModel.files!
                          .map(
                            (e) => FileTagRow(
                              ft: e,
                              onTagClick: (tag) =>
                                  exploreViewModel.onAddTags(tag),
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
                                      await exploreViewModel.changeTagsOfFile(
                                          e, k.newFileTag);
                                    }
                                  },
                                )
                              ],
                              isSelected: exploreViewModel.selectedFiles.isEmpty
                                  ? null
                                  : exploreViewModel.selectedFiles
                                      .any((element) => element.equals(e)),
                              onSelect: (isAdded) =>
                                  exploreViewModel.onSelectFile(isAdded, e),
                            ),
                          )
                          .toList(),
                    ),
                  )
                : const Text("No Data"),
          ],
        ),
      ),
    );
  }
}
