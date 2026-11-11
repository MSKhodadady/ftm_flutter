import 'package:flutter/material.dart';
import 'package:ftm_flutter/icon/zicon_outline_icons.dart';
import 'package:ftm_flutter/views/add/model.dart';
import 'package:ftm_flutter/widget/chosen_tag_list.dart';
import 'package:ftm_flutter/widget/edit_file_tag.dart';
import 'package:ftm_flutter/widget/file_tag_row.dart';
import 'package:ftm_flutter/widget/tag_autocomplete.dart';

class AddPage extends StatelessWidget {
  final AddViewModel addViewModel;
  const AddPage({
    super.key,
    required this.addViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: addViewModel,
      builder: (context, child) => Scaffold(
        floatingActionButton: FloatingActionButton(
            //: done selecting
            onPressed: () async {
              await addViewModel.onPressAdd();
              if (context.mounted) {
                Navigator.pushNamed(context, '/explore');
              }
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
                  chosenTags: addViewModel.chosenTags,
                  onSubmitted: (e) {
                    addViewModel.addChosenTag(e);
                  },
                ),
              ),
              //: tag list
              ChosenTagList(
                  chosenTags: addViewModel.chosenTags,
                  onDeleted: (e) {
                    addViewModel.removeChosenTag(e);
                  }),
              //: selected files
              Column(
                children: addViewModel.selectedFiles
                    .map((e) => FileTagRow(
                          ft: e,
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
                                  addViewModel.changeSelectedFile(
                                      e, k.newFileTag);
                                }
                              },
                            ),
                            IconButton(
                              onPressed: () {
                                addViewModel.removeSelectedFile(e);
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
                      side: WidgetStateProperty.all(BorderSide(
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
