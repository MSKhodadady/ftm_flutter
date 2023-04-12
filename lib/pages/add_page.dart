import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ftm_flutter/data/file_item.dart';
import 'package:ftm_flutter/icon/zicon_outline_icons.dart';
import 'package:ftm_flutter/widget/chosen_tag_list.dart';
import 'package:ftm_flutter/widget/tag_autocomplete.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:ftm_flutter/widget/secondary_button.dart';

typedef OnSelectFile = void Function(FilePickerResult filePickerResult);
typedef OnDeleteFile = void Function(FileItem fileItem);
typedef SetChosenTag = void Function(List<String> chosenTags);

class AddPage extends StatefulWidget {
  final Iterable<FileItem> selectedFiles;
  final List<String> chosenTags;
  final OnSelectFile onSelectFile;
  final OnDeleteFile onDeleteFile;
  final SetChosenTag setChosenTag;

  const AddPage(
      {Key? key,
      required this.selectedFiles,
      required this.chosenTags,
      required this.onSelectFile,
      required this.onDeleteFile,
      required this.setChosenTag})
      : super(key: key);

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /* appBar: AppBar(
        title: const Text("Add"),
        actions: [
          Container(
            margin: const EdgeInsets.all(10),
            child: OutlinedButton(
                style: ButtonStyle(
                    padding: MaterialStateProperty.all(const EdgeInsets.all(1)),
                    side: MaterialStateProperty.all(
                        const BorderSide(color: Colors.white))),
                onPressed: () async {
                  widget.onSelectFile(await FilePicker.platform
                          .pickFiles(allowMultiple: true) ??
                      const FilePickerResult([]));
                },
                child: Text(
                  "Add File",
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                )),
          ),
        ],
      ), */
      body: Container(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TagAutocomplete(
              chosenTags: widget.chosenTags,
              onSubmitted: (e) {
                widget.setChosenTag([...widget.chosenTags, e]);
              },
            ),
            //: tag list
            ChosenTagList(
                chosenTags: widget.chosenTags,
                onDeleted: (e) {
                  widget.setChosenTag(widget.chosenTags
                      .where((element) => element != e)
                      .toList());
                }),
            //: selected files
            Column(
              children: widget.selectedFiles
                  .map((e) => ListTile(
                      title: Text(e.name),
                      // subtitle: Text(e.path),
                      trailing: IconButton(
                        icon: const Icon(ZiconOutline.trash),
                        onPressed: () {
                          widget.onDeleteFile(e);
                        },
                      ),
                      leading: GestureDetector(
                        child:
                            Image.asset('assets/images/placeholder-image.png'),
                        onTap: () {
                          OpenFile.open(e.path);
                        },
                      )))
                  .toList(),
            ),
            OutlinedButton(
                style: ButtonStyle(
                    side: MaterialStateProperty.all(BorderSide(
                        color: Theme.of(context).colorScheme.secondary))),
                onPressed: () async {
                  widget.onSelectFile(await FilePicker.platform
                          .pickFiles(allowMultiple: true) ??
                      const FilePickerResult([]));
                },
                child: Text(
                  "Add more Files ...",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary),
                )),
          ],
        ),
      ),
    );
  }
}
