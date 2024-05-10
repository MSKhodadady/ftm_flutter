import 'package:flutter/material.dart';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:ftm_flutter/widget/file_leading.dart';

class FileTagRow extends StatelessWidget {
  const FileTagRow({
    super.key,
    required this.ft,
    required this.filePath,
    this.onTagClick,
    this.isSelected,
    this.onSelect,
    required this.actions,
  });

  final FileTag ft;
  final String filePath;
  final bool? isSelected;
  final void Function(bool? isAdded)? onSelect;
  final void Function(String tag)? onTagClick;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: Text(ft.fileName),
        leading: SizedBox(
          width: 50,
          child: isSelected == null
              ? GestureDetector(
                  onLongPress: () {
                    if (onSelect != null) {
                      onSelect!(true);
                    }
                  },
                  child: FileLeading(
                    filePath: filePath,
                  ),
                )
              : Checkbox(
                  value: isSelected,
                  onChanged: onSelect,
                ),
        ),
        subtitle: Wrap(
          children: ft.tags
              .map((t) => Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 1),
                    child: GestureDetector(
                      onTap: () {
                        if (onTagClick != null) {
                          onTagClick!(t);
                        }
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
        trailing: isSelected == null
            ? Row(mainAxisSize: MainAxisSize.min, children: actions)
            : null);
  }
}
