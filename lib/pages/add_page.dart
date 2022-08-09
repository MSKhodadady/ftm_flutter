import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ftm_flutter/data/file_item.dart';
import 'package:ftm_flutter/icon/zicon_outline_icons.dart';
import 'package:ftm_flutter/widget/tag_autocomplete.dart';
import 'package:open_file/open_file.dart';

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
      appBar: AppBar(
        title: const Text("Add"),
        actions: [
          IconButton(
              onPressed: () async {
                widget.onSelectFile(
                    await FilePicker.platform.pickFiles(allowMultiple: true) ??
                        const FilePickerResult([]));
              },
              icon: Icon(
                ZiconOutline.plus_2,
                color: Theme.of(context).colorScheme.primaryContainer,
              ))
        ],
      ),
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
            //: suggested tags
            /* SizedBox(
                height: 40,
                child: FutureBuilder(
                    future: _suggestedTagsFuture,
                    builder: (context, snapshot) => snapshot.hasData
                        ? ListView(
                            scrollDirection: Axis.horizontal,
                            children: (snapshot.data as List<String>)
                                .map((e) => InkWell(
                                      child: Chip(
                                        label: Text(e),
                                        visualDensity: const VisualDensity(
                                            horizontal: 1, vertical: -4),
                                      ),
                                      onTap: () async {
                                        widget.setChosenTag(
                                            [...widget.chosenTags, e]);
                                        _textController.clear();
                                      },
                                    ))
                                .toList())
                        : const Text("loading"))),
            //: text field
            TextField(
              controller: _textController,
              focusNode: _textFocus,
              onSubmitted: (txt) {
                widget.setChosenTag([...widget.chosenTags, txt]);
                _textController.clear();
              },
            ), */
            /* TypeAheadField<String>(
                textFieldConfiguration: TextFieldConfiguration(
                    controller: _textController,
                    focusNode: _textFocus,
                    decoration: const InputDecoration(
                      labelText: 'Enter tag',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (text) {
                      _textController.text = "";
                      _textFocus.requestFocus();
                      widget.setChosenTag([...widget.chosenTags, text]);
                    }),
                suggestionsCallback: (txt) async {
                  var ts = await tagsList();
                  return txt == ''
                      ? ts
                          .where((element) =>
                              !widget.chosenTags.any((ct) => ct == element))
                          .take(5)
                          .toList()
                      : ts
                          // TODO contains case-intensive
                          .where((element) => element.contains(txt))
                          .where((element) =>
                              !widget.chosenTags.any((ct) => ct == element))
                          .take(5)
                          .toList();
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title: Text(suggestion),
                  );
                },
                onSuggestionSelected: (suggestion) {
                  widget.setChosenTag([...widget.chosenTags, suggestion]);
                  _textFocus.requestFocus();
                  _textController.text = '';
                  // _suggestionsBoxController.close();
                  // _suggestionsBoxController.open();
                },
                hideOnEmpty: true,
                suggestionsBoxController: _suggestionsBoxController,
                getImmediateSuggestions: true), */
            //: tag list
            Wrap(
              children: widget.chosenTags
                  .map((e) => Container(
                        margin: const EdgeInsets.only(right: 10),
                        child: Chip(
                          onDeleted: () {
                            widget.setChosenTag(widget.chosenTags
                                .where((element) => element != e)
                                .toList());
                          },
                          label: Text(e),
                          backgroundColor: Colors.grey[100],
                        ),
                      ))
                  .toList(),
            ),
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
          ],
        ),
      ),
    );
  }
}
