import 'package:flutter/material.dart';

class ChosenTagList extends StatelessWidget {
  const ChosenTagList({
    Key? key,
    required this.chosenTags,
    required this.onDeleted,
  }) : super(key: key);

  final List<String> chosenTags;
  final Function(String tag) onDeleted;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.center,
      children: chosenTags
          .map((e) => Container(
                margin: const EdgeInsets.only(right: 10),
                child: Chip(
                  onDeleted: () => onDeleted(e),
                  label: Text(e),
                  // backgroundColor: Colors.grey[100],
                  color: MaterialStatePropertyAll(
                      Theme.of(context).colorScheme.secondary),
                  side: const BorderSide(color: Colors.transparent),
                ),
              ))
          .toList(),
    );
  }
}
