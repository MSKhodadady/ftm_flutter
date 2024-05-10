import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ftm_flutter/widget/chosen_tag_list.dart';
import 'package:ftm_flutter/widget/tag_autocomplete.dart';
import 'package:path/path.dart' as path;

import '../data/file_tag.dart';

class EditFileTag extends StatefulWidget {
  const EditFileTag(
      {Key? key, required this.oldFileTag, required this.isImport})
      : super(key: key);

  final FileTag oldFileTag;
  final bool isImport;

  @override
  State<EditFileTag> createState() => _EditFileTagState();
}

class _EditFileTagState extends State<EditFileTag> {
  final _textController = TextEditingController();
  List<String> chosenTags = [];
  var addTag = false;
  String? anotherFileExists;

  bool deleteFileConfirm = false;

  @override
  void initState() {
    super.initState();

    _textController.text = widget.oldFileTag.fileName;
    chosenTags = widget.oldFileTag.tags;
  }

  Future<void> onConfirm() async {
    //: not changed
    if (_textController.text == widget.oldFileTag.fileName &&
        listEquals(widget.oldFileTag.tags, chosenTags)) {
      Navigator.of(context).pop(NotChanged());
      return;
    }
    try {
      if (!mounted) return;

      final newFileName = _textController.text;

      final newFileTag = FileTag(
        newFileName,
        chosenTags,
        widget.isImport
            ? widget.oldFileTag.path
            : path.join(
                File(widget.oldFileTag.path).parent.path,
                newFileName,
              ),
      );

      // ignore: use_build_context_synchronously
      Navigator.of(context).pop(Changed(newFileTag));
    } on FileExistsException {
      setState(() {
        anotherFileExists = "another file exists with this name";
      });

      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          anotherFileExists = null;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actions: [
        ElevatedButton(
          onPressed: onConfirm,
          child: const Text("Confirm"),
        ),
      ],
      content: SizedBox(
        width: 300,
        height: 300,
        child: ListView(
          children: [
            const SizedBox(
              height: 10,
            ),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: "file name",
                  label: const Text("file name"),
                  errorText: anotherFileExists),
            ),
            const SizedBox(
              height: 10,
            ),
            addTag
                ? TagAutocomplete(
                    onSubmitted: (p0) {
                      setState(() {
                        chosenTags = [...chosenTags, p0];
                      });
                    },
                    chosenTags: chosenTags)
                : ElevatedButton(
                    onPressed: () {
                      setState(() {
                        addTag = true;
                      });
                    },
                    child: const Text("Add Tag")),
            const SizedBox(
              height: 10,
            ),
            ChosenTagList(
              chosenTags: chosenTags,
              onDeleted: (e) {
                setState(() {
                  chosenTags =
                      chosenTags.where((element) => element != e).toList();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

abstract class ActionResult {}

class NotChanged implements ActionResult {}

class Changed implements ActionResult {
  final FileTag newFileTag;

  Changed(this.newFileTag);
}
