import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:ftm_flutter/controllers/route.dart';
import 'package:ftm_flutter/pages/add_page.dart';
import 'package:ftm_flutter/pages/explore_page.dart';
import 'package:ftm_flutter/data/file_item.dart';
import 'package:ftm_flutter/icon/zicon_outline_icons.dart';
import 'package:ftm_flutter/controllers/selected_files.dart';
import 'package:ftm_flutter/widget/select_file.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';

Widget gotoRoute(RoutePages r) {
  switch (r) {
    case RoutePages.explorePage:
      return const ExplorePage();
    case RoutePages.addPage:
      return const AddPage();
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
            body: gotoRoute(routeController.route),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            bottomNavigationBar: BottomNavigationBar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              selectedItemColor: Theme.of(context).colorScheme.onPrimary,
              unselectedItemColor: Theme.of(context).colorScheme.onPrimary,
              selectedFontSize: 15,
              selectedIconTheme: const IconThemeData(size: 28),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(ZiconOutline.search),
                  label: "Explore",
                ),
                BottomNavigationBarItem(
                    icon: Icon(ZiconOutline.plus_2), label: "Import"),
              ],
              currentIndex: getRouteIndex(routeController.route),
              onTap: (index) async {
                switch (index) {
                  case 0: //: explore page
                    if (routeController.route != RoutePages.explorePage) {
                      routeController.setRoute(RoutePages.explorePage);

                      selectedFilesController.set([]);
                    }
                    break;
                  case 1: // add page
                    if (routeController.route != RoutePages.addPage) {
                      selectedFilesController.set([]);

                      showDialog(
                        context: context,
                        builder: (context) {
                          return Dialog(
                            child: SelectFile(doneSelection: (files) async {
                              final status = await checkAllFilesExist(
                                  files.map((e) => FileItem(basename(e), e)));

                              if (status.exists.isNotEmpty) {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                        "${status.exists.length} file(s) exists: ${status.exists.map((e) => e.name).join(", ")}")));
                              }

                              selectedFilesController
                                  .set(status.notExists.toList());

                              routeController.setRoute(RoutePages.addPage);

                              // ignore: use_build_context_synchronously
                              Navigator.pop(context);
                            }),
                          );
                        },
                      );
                    }
                    break;
                }
              },
            ),
          ),
        ),
      );
}
