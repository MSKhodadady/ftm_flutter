import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:ftm_flutter/icon/zicon_outline_icons.dart';
import 'package:ftm_flutter/controllers/selected_files.dart';
import 'package:get/get.dart';
import '../io_manager.dart';

class MainLayoutWrapper extends StatelessWidget {
  const MainLayoutWrapper(
      {super.key, required this.selectedIndex, required this.child});

  final int selectedIndex;
  final Widget child;

  final destinations = const [
    NavigationDestination(
      icon: Icon(ZiconOutline.search),
      label: "Explore",
    ),
    NavigationDestination(
      icon: Icon(ZiconOutline.plus_2),
      label: "Import",
    ),
    NavigationDestination(
      icon: Icon(ZiconOutline.trash),
      label: "Trash",
    ),
    NavigationDestination(
      icon: Icon(ZiconOutline.up_1),
      label: "More",
    )
  ];

  @override
  Widget build(BuildContext context) => GetBuilder<SelectedFilesController>(
        init: SelectedFilesController(),
        builder: (selectedFilesController) => Scaffold(
          //: find body
          body: child,
          //:
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: NavigationBar(
            destinations: destinations,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) async {
              switch (index) {
                case 0: //: explore page
                  Navigator.pushNamed(context, '/explore');
                  break;
                case 1: //: add page
                  selectedFilesController.clear();

                  if (isDesktop()) {
                    var result = await FilePicker.platform
                        .pickFiles(allowMultiple: true);

                    if (result != null) {
                      selectedFilesController.add(result.files
                          .where((element) => element.path != null)
                          .map((e) => FileTag(e.name, [], e.path ?? ""))
                          .toList());

                      // ignore: use_build_context_synchronously
                      Navigator.pushNamed(context, '/add');
                    }
                  } else {
                    Navigator.pushNamed(context, '/select-files');
                  }
                  break;
                case 2: //: trash page

                  Navigator.pushNamed(context, '/trash');
                  break;

                case 3:
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Container(
                      margin: const EdgeInsets.only(top: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          ListTile(
                            title: const Text("Drivers"),
                            leading: const Icon(ZiconOutline.settings_1),
                            onTap: () {
                              Navigator.of(context).pop();

                              Navigator.pushNamed(context, '/drivers');
                            },
                          )
                        ],
                      ),
                    ),
                  );
              }
            },
          ),
        ),
      );
}
