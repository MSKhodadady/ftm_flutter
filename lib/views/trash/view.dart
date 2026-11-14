import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ftm_flutter/hooks/loading.dart';
import 'package:ftm_flutter/icon/zicon_outline_icons.dart';
import 'package:ftm_flutter/views/trash/model.dart';
import 'package:ftm_flutter/widget/file_tag_row.dart';
import 'package:ftm_flutter/widget/yes_no_dialog.dart';

class TrashView extends HookWidget {
  final TrashViewModel vm;

  const TrashView({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final loadingHook = LoadingHook();

    return ListenableBuilder(
      listenable: vm,
      builder: (context, child) => Scaffold(
        appBar: AppBar(
          title: const Text("Trash"),
          actions: [
            OverflowBar(
              children: [
                TextButton(
                    onPressed: () async {
                      final k = await showDialog<bool?>(
                          context: context,
                          builder: (context) {
                            return const YesNoDialog();
                          });

                      if (k == true) {
                        loadingHook.withLoading(vm.deleteAllOrSelectedFiles);
                      }
                    },
                    child: Text(
                      vm.selectedFiles.isEmpty ? "Delete All" : "Delete",
                    )),
                TextButton(
                    onPressed: () =>
                        loadingHook.withLoading(vm.restoreAllOrSelected),
                    child: Text(
                      vm.selectedFiles.isEmpty ? "Restore All" : "Restore",
                    ))
              ],
            )
          ],
        ),
        body: ListView(children: [
          vm.files != null && !loadingHook.isLoading.value
              ? Column(
                  children: vm.files!
                      .map((e) => FileTagRow(
                            ft: e,
                            isSelected: vm.selectedFiles.isEmpty
                                ? null
                                : vm.selectedFiles.contains(e),
                            onSelect: (isAdded) =>
                                vm.addRemoveSelectedFile(isAdded, e),
                            actions: [
                              IconButton(
                                  onPressed: () async {
                                    final bool? k = await showDialog(
                                        context: context,
                                        builder: (c) {
                                          return const YesNoDialog();
                                        });

                                    if (k == true) {
                                      vm.deleteFileTag(e);
                                    }
                                  },
                                  icon: const Icon(ZiconOutline.trash)),
                              IconButton(
                                  onPressed: () => vm.restoreFileTag(e),
                                  icon: const Icon(ZiconOutline.replay))
                            ],
                          ))
                      .toList(),
                )
              : Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                    ],
                  ),
                )
        ]),
      ),
    );
  }
}
