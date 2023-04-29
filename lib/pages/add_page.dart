import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ftm_flutter/data/file_item.dart';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:ftm_flutter/reducer/route.dart';
import 'package:ftm_flutter/icon/zicon_outline_icons.dart';
import 'package:ftm_flutter/reducer/selected_files.dart';
import 'package:ftm_flutter/widget/chosen_tag_list.dart';
import 'package:ftm_flutter/widget/tag_autocomplete.dart';
import 'package:get/get.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:tuple/tuple.dart';

class AddPage extends HookWidget {
  const AddPage({super.key});

  void onSelectFile(
      FilePickerResult result,
      SelectedFilesController selectedFilesController,
      BuildContext context,
      bool Function() isMounted) {
    //: convert selected files to FileItem
    var newSelectedFiles =
        result.files.map((e) => FileItem(e.name, e.path ?? "NO-PATH"));

    //: check if files exist in our dir & db
    /* var status = await  */ checkAllFilesExist(newSelectedFiles)
        .then((status) {
      if (status.exists.isNotEmpty) {
        if (!isMounted()) return; //: for using context in async
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "${status.exists.length} file(s) exists: ${status.exists.map((e) => e.name).join(", ")}")));
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
        /* final selectedBefore = status.notExists
              .where((s) => selectedFilesStore.state.every((e) => e.equals(s))); */
        final selectedBefore = status.notExists.where((s) =>
            selectedFilesController.selectedFiles.every((e) => e.equals(s)));

        if (!isMounted()) return; //: for using context in async
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "selected before: ${selectedBefore.map((e) => e.name).join(", ")}")));
      }

      //: update
      selectedFilesController.add(ys.toList());
    });
  }

  void onDeleteFile(
      FileItem fileItem, SelectedFilesController selectedFilesController) {
    selectedFilesController.set(selectedFilesController.selectedFiles
        .where((element) => !element.equals(fileItem))
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    final isMounted = useIsMounted();

    final chosenTags = useState<List<String>>([]);

    return GetBuilder<SelectedFilesController>(
      builder: (selectedFilesController) => Scaffold(
        floatingActionButton: GetBuilder<RouteController>(
          builder: (routeController) => FloatingActionButton(
              onPressed: () async {
                await Future.wait(selectedFilesController.selectedFiles
                    .map((e) =>
                        Tuple2(FileTag(e.name, chosenTags.value), e.path))
                    .map((e) => insertAndMove_(e.item1, e.item2, true)));

                routeController.setRoute(RoutePages.explorePage);
              },
              child: const Icon(Icons.add)),
        ),
        body: Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              TagAutocomplete(
                chosenTags: chosenTags.value,
                onSubmitted: (e) {
                  chosenTags.value = [...chosenTags.value, e];
                },
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
                    .map((e) => ListTile(
                        title: Text(e.name),
                        trailing: IconButton(
                          icon: const Icon(ZiconOutline.trash),
                          onPressed: () {
                            onDeleteFile(e, selectedFilesController);
                          },
                        ),
                        leading: GestureDetector(
                          child: Image.asset(
                              'assets/images/placeholder-image.png'),
                          onTap: () {
                            OpenFile.open(e.path);
                          },
                        )))
                    .toList(),
              ),
              OutlinedButton(
                  style: ButtonStyle(
                      side: MaterialStateProperty.all(BorderSide(
                          color: Theme.of(context).colorScheme.secondary))),
                  onPressed: () async {
                    onSelectFile(
                        await FilePicker.platform
                                .pickFiles(allowMultiple: true) ??
                            const FilePickerResult([]),
                        selectedFilesController,
                        context,
                        isMounted);
                  },
                  child: Text(
                    "Add more Files ...",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
