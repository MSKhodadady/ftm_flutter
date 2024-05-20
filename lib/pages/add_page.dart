import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:ftm_flutter/controllers/selected_files.dart';
import 'package:ftm_flutter/icon/zicon_outline_icons.dart';
import 'package:ftm_flutter/widget/chosen_tag_list.dart';
import 'package:ftm_flutter/widget/edit_file_tag.dart';
import 'package:ftm_flutter/widget/file_tag_row.dart';
import 'package:ftm_flutter/widget/tag_autocomplete.dart';
import 'package:get/get.dart';

class AddPage extends HookWidget {
  const AddPage({super.key});

  @override
  Widget build(BuildContext context) {
    final chosenTags = useState<List<String>>([]);

    final mounted = useIsMounted();

    return GetBuilder<SelectedFilesController>(
      builder: (selectedFilesController) => Scaffold(
        floatingActionButton: FloatingActionButton(
            //: done selecting
            onPressed: () async {
              await Future.wait(selectedFilesController.selectedFiles
                  .map((e) => FileTag(e.fileName,
                      {...e.tags, ...chosenTags.value}.toList(), e.path))
                  .map((e) => insertAndMove_(e)));

              if (!mounted()) return;
              Navigator.pushNamed(context, '/explore');
            },
            child: const Icon(Icons.add)),
        body: Container(
          margin: const EdgeInsets.only(bottom: 100),
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                child: TagAutocomplete(
                  title: "Choose tags for all selected files",
                  chosenTags: chosenTags.value,
                  onSubmitted: (e) {
                    chosenTags.value = [...chosenTags.value, e];
                  },
                ),
              ),
              //: tag list
              ChosenTagList(
                  chosenTags: chosenTags.value,
                  onDeleted: (e) {
                    chosenTags.value = chosenTags.value
                        .where((element) => element != e)
                        .toList();
                  }),
              //: selected files
              Column(
                children: selectedFilesController.selectedFiles
                    .map((e) => FileTagRow(
                          ft: e,
                          filePath: e.path,
                          onTagClick: (s) {},
                          actions: [
                            IconButton(
                              icon: const Icon(ZiconOutline.pen),
                              onPressed: () async {
                                var k = await showDialog<ActionResult>(
                                    context: context,
                                    builder: (context) {
                                      return EditFileTag(
                                        oldFileTag: e,
                                        isImport: true,
                                      );
                                    });

                                if (k is Changed) {
                                  selectedFilesController.changeFile(
                                      e, k.newFileTag);
                                }
                              },
                            ),
                            IconButton(
                              onPressed: () {
                                selectedFilesController.remove(e);
                              },
                              icon: const Icon(ZiconOutline.trash),
                            )
                          ],
                        ))
                    .toList(),
              ),
              Container(
                margin: const EdgeInsets.all(10),
                child: OutlinedButton(
                  style: ButtonStyle(
                      side: MaterialStateProperty.all(BorderSide(
                          color: Theme.of(context).colorScheme.secondary))),
                  onPressed: () {
                    Navigator.pushNamed(context, '/select-files');
                  },
                  child: Text(
                    "Add more Files ...",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
