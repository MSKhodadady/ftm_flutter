import 'package:flutter/material.dart';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:ftm_flutter/io_manager.dart';

typedef TagAutocompleteOnSelected = void Function(String);

class TagAutocomplete extends StatefulWidget {
  final TagAutocompleteOnSelected onSubmitted;
  final List<String> chosenTags;
  final String? title;

  const TagAutocomplete(
      {Key? key,
      required this.onSubmitted,
      required this.chosenTags,
      this.title})
      : super(key: key);

  @override
  State<TagAutocomplete> createState() => _TagAutocompleteState();
}

class _TagAutocompleteState extends State<TagAutocomplete> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocus = FocusNode();
  Future<List<String>> _suggestedTagsFuture = Future.value([]);
  List<String> suggestedTags = [];

  @override
  void initState() {
    super.initState();

    _textController.addListener(() {
      setState(() {
        _suggestedTagsFuture = _autoComplete();
      });
    });
  }

  Future<List<String>> _autoComplete() async {
    final txt = _textController.text;
    // final ts = await tagsList();
    final ts = await tagsList_();
    return txt == ''
        ? ts
            .where((element) => widget.chosenTags.every((ct) => ct != element))
            .where((element) => element != trashTag)
            .take(5)
            .toList()
        : ts
            // TODO contains case-intensive
            .where((element) => element.contains(txt))
            .where((element) => widget.chosenTags.every((ct) => ct != element))
            .where((element) => element != trashTag)
            .take(5)
            .toList();
  }

  @override
  Widget build(BuildContext context) {
    _suggestedTagsFuture = _autoComplete();
    return Column(
      children: [
        //: text field
        TextField(
          controller: _textController,
          focusNode: _textFocus,
          onSubmitted: (txt) {
            widget.onSubmitted(txt);
            _textController.clear();
            _textFocus.requestFocus();
          },
          decoration: InputDecoration(
              border: const OutlineInputBorder(),
              // hintText: "Enter Tag Name",
              label: Text(widget.title ?? "Choose Tag")),
        ),
        SizedBox(
            height: 40,
            child: FutureBuilder(
                future: _suggestedTagsFuture,
                builder: (context, snapshot) => snapshot.hasData
                    ? ListView(
                        scrollDirection: Axis.horizontal,
                        children: (snapshot.data as List<String>)
                            .map((e) => InkWell(
                                  child: Container(
                                    padding: const EdgeInsets.only(right: 1),
                                    child: Chip(
                                      label: Text(e),
                                      color: MaterialStatePropertyAll(
                                          Theme.of(context)
                                              .colorScheme
                                              .secondary),
                                      side: const BorderSide(
                                          color: Colors.transparent),
                                      visualDensity: const VisualDensity(
                                          horizontal: 1, vertical: -4),
                                    ),
                                  ),
                                  onTap: () async {
                                    widget.onSubmitted(e);
                                    _textController.clear();
                                  },
                                ))
                            .toList())
                    : const Text("loading"))),
      ],
    );
  }
}
