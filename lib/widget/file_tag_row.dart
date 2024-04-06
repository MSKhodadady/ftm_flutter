import 'package:flutter/material.dart';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:ftm_flutter/icon/zicon_outline_icons.dart';
import 'package:ftm_flutter/widget/edit_file_tag.dart';
import 'package:ftm_flutter/widget/file_leading.dart';

class FileTagRow extends StatelessWidget {
  const FileTagRow({
    super.key,
    required this.ft,
    required this.filePath,
    required this.onTagClick,
    required this.onFileAction,
    this.isImport = false,
  });

  final FileTag ft;
  final String filePath;
  final bool isImport;
  final void Function(String) onTagClick;
  final void Function(ActionResult?) onFileAction;

  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: Text(ft.fileName),
        leading: SizedBox(
          width: 50,
          child: FileLeading(
            filePath: filePath,
          ),
        ),
        subtitle: Wrap(
          children: ft.tags
              .map((t) => Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 1),
                    child: GestureDetector(
                      onTap: () {
                        onTagClick(t);
                      },
                      child: Chip(
                        label: Text(t),
                        side: const BorderSide(color: Colors.transparent),
                        color: MaterialStatePropertyAll(
                            Theme.of(context).colorScheme.secondary),
                        visualDensity:
                            const VisualDensity(horizontal: -4, vertical: -4),
                      ),
                    ),
                  ))
              .toList(),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(ZiconOutline.pen),
              onPressed: () async {
                var k = await showDialog<ActionResult>(
                    context: context,
                    builder: (context) {
                      return EditFileTag(oldFileTag: ft);
                    });

                onFileAction(k);
              },
            ),
            IconButton(
              onPressed: () {
                onFileAction(Deleted());
              },
              icon: const Icon(ZiconOutline.trash),
            )
          ],
        ));
  }
}
