import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:ftm_flutter/pages/add_page.dart';
import 'package:ftm_flutter/pages/explore_page.dart';
import 'package:ftm_flutter/data/file_item.dart';
import 'package:ftm_flutter/icon/zicon_outline_icons.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({
    Key? key,
  }) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

enum RoutePages { homePage, addPage, explorePage }

class _MainLayoutState extends State<MainLayout> {
  List<FileItem> selectedFiles = [];
  List<String> chosenTags = [];
  bool copyFiles = true;

  var route = RoutePages.explorePage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: route == RoutePages.explorePage
          ? const ExplorePage()
          : route == RoutePages.addPage
              ? AddPage(
                  selectedFiles: selectedFiles,
                  chosenTags: chosenTags,
                  onSelectFile: (result) async {
                    //: convert selected files to FileItem
                    var newSelectedFiles = result.files
                        .map((e) => FileItem(e.name, e.path ?? "NO-1PATH"));

                    //: check if files exist in our dir & db
                    var status = await checkFilesExist(newSelectedFiles);

                    if (status.exists.isNotEmpty) {
                      if (!mounted) return; //: for using context in async
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              "${status.exists.length} file(s) exists: ${status.exists.map((e) => e.name).join(", ")}")));
                    }

                    //: check if files selected before
                    final ys = status.notExists.where(
                        (sf) => selectedFiles.every((e) => !e.equals(sf)));
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
                      final selectedBefore = status.notExists.where(
                          (s) => selectedFiles.every((e) => e.equals(s)));

                      if (!mounted) return; //: for using context in async
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              "selected before: ${selectedBefore.map((e) => e.name).join(", ")}")));
                    }

                    //: update
                    setState(() {
                      selectedFiles = [...selectedFiles, ...ys];
                    });
                  },
                  onDeleteFile: (fileItem) {
                    setState(() {
                      selectedFiles = selectedFiles
                          .where((element) => !element.equals(fileItem))
                          .toList();
                    });
                  },
                  setChosenTag: (xs) {
                    setState(() {
                      chosenTags = xs;
                    });
                  },
                )
              : Container(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (route != RoutePages.addPage) {
            setState(() {
              selectedFiles = [];
            });

            final result =
                await FilePicker.platform.pickFiles(allowMultiple: true);

            if (result != null) {
              //: check if files exist
              final status = await checkFilesExist(result.files
                  .map((e) => FileItem(e.name, e.path ?? "NO-PATH")));
              if (status.exists.isNotEmpty) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        "${status.exists.length} file(s) exists: ${status.exists.map((e) => e.name).join(", ")}")));
              }

              setState(() {
                selectedFiles = status.notExists.toList();
              });
            }

            setState(() {
              route = RoutePages.addPage;
            });
          } else {
            await Future.wait(selectedFiles
                .map((e) => [FileTag(e.name, chosenTags), e.path])
                .map((e) => insertAndMove(e[0] as FileTag, e[1], true)));

            setRouteExplore();
          }
        },
        mini: true,
        backgroundColor: route == RoutePages.addPage
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.secondary,
        child: Icon(
          ZiconOutline.plus,
          color: route == RoutePages.addPage
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSecondary,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).colorScheme.primary,
        shape: const CircularNotchedRectangle(),
        child: IconTheme(
            data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // TODO
                  /* IconButton(
                      onPressed: () {},
                      icon: const Icon(ZiconOutline.settings_2)), */
                  IconButton(
                      onPressed: () {
                        setRouteExplore();
                      },
                      icon: const Icon(ZiconOutline.search)),
                  // TODO
                  /* IconButton(
                      onPressed: () {}, icon: const Icon(ZiconOutline.sound)), */

                  // TODO
                  IconButton(
                      // onPressed: t.printDirectories,
                      onPressed: () async {
                        print(await tagsList());
                      },
                      icon: const Icon(ZiconOutline.image_placeholder)),
                ],
              ),
            )),
      ),
    );
  }

  setRouteExplore() {
    setState(() {
      route = RoutePages.explorePage;
      chosenTags = [];
      selectedFiles = [];
    });
  }
}
