import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:ftm_flutter/controllers/route.dart';
import 'package:ftm_flutter/controllers/selected_files.dart';
import 'package:ftm_flutter/widget/chosen_tag_list.dart';
import 'package:ftm_flutter/widget/edit_file_tag.dart';
import 'package:ftm_flutter/widget/file_tag_row.dart';
import 'package:ftm_flutter/widget/tag_autocomplete.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';

class AddPage extends HookWidget {
  const AddPage({super.key});

  void onSelectFile(
      List<String> files,
      SelectedFilesController selectedFilesController,
      BuildContext context) async {
    //: convert selected files to FileItem
    var newSelectedFiles = files.map((e) => FileTag(basename(e), [], e));
    //: check if files exist in our dir & db
    var status = await checkAllFilesExist(newSelectedFiles);

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

    //: check if files selected before
    final ys = status.notExists.where((sf) =>
        selectedFilesController.selectedFiles.every((e) => !e.equals(sf)));
    //: why we should use selectedFiles.*toList()* No No
    //: why we used selectedFiles as List not iterable
    //: because the selectedFiles is an Iterable, means it is not evaluated,
    //: then we must create a new iterable based on information from selectedFiles,
    //: and put that again in selectedFiles,
    //: means that we want create an iterable based on an iterable,
    //: and put the result in later mentioned iterable!!!
    //: that will cause STACK OVERFLOW

    //: notify user for selected before files
    if (ys.length != status.notExists.length) {
      final selectedBefore = status.notExists.where((s) =>
          selectedFilesController.selectedFiles.every((e) => e.equals(s)));

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "selected before: ${selectedBefore.map((e) => e.fileName).join(", ")}",
          ),
        ),
      );
    }

    //: update
    selectedFilesController.add(ys.toList());
  }

  void onDeleteFile(
    FileTag ft,
    SelectedFilesController selectedFilesController,
  ) {
    selectedFilesController.set(selectedFilesController.selectedFiles
        .where((element) => !element.equals(ft))
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    final chosenTags = useState<List<String>>([]);

    return GetBuilder<SelectedFilesController>(
      builder: (selectedFilesController) => Scaffold(
        floatingActionButton: GetBuilder<RouteController>(
          builder: (routeController) => FloatingActionButton(
              onPressed: () async {
                await Future.wait(selectedFilesController.selectedFiles
                    .map((e) => FileTag(e.fileName, chosenTags.value, e.path))
                    .map((e) => insertAndMove_(e)));

                routeController.setRoute(RoutePages.explorePage);
              },
              child: const Icon(Icons.add)),
        ),
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
                        ft: FileTag(e.fileName, [], e.path),
                        filePath: e.path,
                        isImport: true,
                        onTagClick: (s) {},
                        onFileAction: (s) {
                          if (s is Changed) {
                          } else if (s is Deleted) {}
                        }))
                    .toList(),
              ),
              Container(
                margin: const EdgeInsets.all(10),
                child: OutlinedButton(
                    style: ButtonStyle(
                        side: MaterialStateProperty.all(BorderSide(
                            color: Theme.of(context).colorScheme.secondary))),
                    onPressed: () {
                      RouteController.to.setRoute(RoutePages.selectFilePage);
                    },
                    child: Text(
                      "Add more Files ...",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary),
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
