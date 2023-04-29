import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:ftm_flutter/controllers/route.dart';
import 'package:ftm_flutter/pages/add_page.dart';
import 'package:ftm_flutter/pages/explore_page.dart';
import 'package:ftm_flutter/data/file_item.dart';
import 'package:ftm_flutter/icon/zicon_outline_icons.dart';
import 'package:ftm_flutter/controllers/selected_files.dart';
import 'package:get/get.dart';

class MainLayout extends HookWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final isMounted = useIsMounted();

    return GetBuilder<RouteController>(
      init: RouteController(),
      builder: (routeController) => GetBuilder<SelectedFilesController>(
        init: SelectedFilesController(),
        builder: (controller) => Scaffold(
          body: routeController.route == RoutePages.explorePage
              ? const ExplorePage()
              : routeController.route == RoutePages.addPage
                  ? const AddPage()
                  : Container(),
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
                  icon: Icon(ZiconOutline.plus_2), label: "Import")
            ],
            currentIndex: /* routeStore.state */ routeController.route ==
                    RoutePages.explorePage
                ? 0
                : /* routeStore.state */ routeController.route ==
                        RoutePages.addPage
                    ? 1
                    : 0,
            onTap: (index) async {
              switch (index) {
                case 0:
                  if (routeController.route != RoutePages.explorePage) {
                    RouteController.to.setRoute(RoutePages.explorePage);

                    controller.set([]);
                  }
                  break;
                case 1:
                  if (routeController.route != RoutePages.addPage) {
                    controller.set([]);

                    var result = await FilePicker.platform
                        .pickFiles(allowMultiple: true);
                    if (result != null) {
                      //: check if files exist
                      final status = await checkAllFilesExist(result.files
                          .map((e) => FileItem(e.name, e.path ?? "NO-PATH")));
                      if (status.exists.isNotEmpty) {
                        if (!isMounted()) return;
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                "${status.exists.length} file(s) exists: ${status.exists.map((e) => e.name).join(", ")}")));
                      }

                      controller.set(status.notExists.toList());
                    }

                    RouteController.to.setRoute(RoutePages.addPage);
                  }
                  break;
              }
            },
          ),
        ),
      ),
    );
  }
}
