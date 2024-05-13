import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ftm_flutter/controllers/route.dart';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:ftm_flutter/pages/add_page.dart';
import 'package:ftm_flutter/pages/explore_page.dart';
import 'package:ftm_flutter/icon/zicon_outline_icons.dart';
import 'package:ftm_flutter/controllers/selected_files.dart';
import 'package:ftm_flutter/pages/select_file.dart';
import 'package:ftm_flutter/pages/trash_page.dart';
import 'package:get/get.dart';

Widget gotoRoute(RoutePages r) {
  switch (r) {
    case RoutePages.explorePage:
      return const ExplorePage();
    case RoutePages.addPage:
      return const AddPage();
    case RoutePages.selectFilePage:
      return const SelectFile();
    case RoutePages.trashPage:
      return const TrashPage();
    default:
      return Container();
  }
}

int getRouteIndex(RoutePages r) {
  switch (r) {
    case RoutePages.explorePage:
      return 0;
    case RoutePages.addPage:
      return 1;
    case RoutePages.trashPage:
      return 2;
    default:
      return 0;
  }
}

class MainLayout extends HookWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) => GetBuilder<RouteController>(
        init: RouteController(),
        builder: (routeController) => GetBuilder<SelectedFilesController>(
          init: SelectedFilesController(),
          builder: (selectedFilesController) => Scaffold(
            //: find body
            body: gotoRoute(routeController.route),
            //:
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            bottomNavigationBar: routeController.route ==
                    RoutePages.selectFilePage
                ? null
                : BottomNavigationBar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    selectedItemColor: Theme.of(context).colorScheme.onPrimary,
                    unselectedItemColor:
                        Theme.of(context).colorScheme.onPrimary,
                    selectedFontSize: 15,
                    selectedIconTheme: const IconThemeData(size: 28),
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(ZiconOutline.search),
                        label: "Explore",
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(ZiconOutline.plus_2),
                        label: "Import",
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(ZiconOutline.trash),
                        label: "Trash",
                      ),
                    ],
                    currentIndex: getRouteIndex(routeController.route),
                    onTap: (index) async {
                      switch (index) {
                        case 0: //: explore page
                          if (routeController.route != RoutePages.explorePage) {
                            routeController.setRoute(RoutePages.explorePage);

                            selectedFilesController.clear();
                          }
                          break;
                        case 1: //: add page
                          if (routeController.route != RoutePages.addPage) {
                            selectedFilesController.clear();

                            if (Platform.isWindows) {
                              var result = await FilePicker.platform
                                  .pickFiles(allowMultiple: true);

                              if (result != null) {
                                selectedFilesController.add(result.files
                                    .where((element) => element.path != null)
                                    .map((e) =>
                                        FileTag(e.name, [], e.path ?? ""))
                                    .toList());

                                routeController.setRoute(RoutePages.addPage);
                              }
                            } else {
                              routeController
                                  .setRoute(RoutePages.selectFilePage);
                            }
                          }
                          break;
                        case 2: //: trash page
                          if (routeController.route != RoutePages.trashPage) {
                            routeController.setRoute(RoutePages.trashPage);
                          }
                      }
                    },
                  ),
          ),
        ),
      );
}
