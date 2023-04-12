import 'package:flutter/material.dart';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:ftm_flutter/files.dart';
import 'package:ftm_flutter/widget/edit_file_tag.dart';
import 'package:ftm_flutter/widget/tag_autocomplete.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path/path.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({Key? key}) : super(key: key);

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  Future<List<FileTag>>? fileTagsFuture;

  List<String> chosenTags = [];

  @override
  void initState() {
    super.initState();

    // fileTagsFuture = filesList();
    fileTagsFuture = filesListTagFilter_(chosenTags);
  }

  void _refresh() {
    setState(() {
      fileTagsFuture = filesListTagFilter_(chosenTags);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /* appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))
        ],
      ), */
      body: Container(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            //: tag chooser
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 10,
                  fit: FlexFit.loose,
                  child: TagAutocomplete(
                      onSubmitted: (tag) {
                        setState(() {
                          chosenTags = [...chosenTags, tag];
                        });

                        _refresh();
                      },
                      chosenTags: chosenTags),
                ),
                Flexible(
                    flex: 2,
                    fit: FlexFit.tight,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 10),
                      child: TextButton(
                        onPressed: _refresh,
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                                Theme.of(context).colorScheme.secondary)),
                        child: Icon(
                          Icons.refresh,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                    ))
              ],
            ),
            //: chosen tags
            AnimatedSize(
              duration: const Duration(milliseconds: 500),
              child: SizedBox(
                height: chosenTags.isEmpty ? 0 : 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: chosenTags
                      .map((e) => Container(
                            padding: const EdgeInsets.only(left: 5),
                            child: Chip(
                              label: Text(e),
                              onDeleted: () {
                                setState(() {
                                  chosenTags = chosenTags
                                      .where((element) => element != e)
                                      .toList();
                                });
                                _refresh();
                              },
                              visualDensity: VisualDensity.compact,
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            //: fileTags
            FutureBuilder(
              future: fileTagsFuture,
              builder: (context, snapshot) => snapshot.hasData
                  ? Column(
                      children: (snapshot.data as Iterable<FileTag>)
                          .map((e) => ListTile(
                                title: Text(e.fileName),
                                leading: InkWell(
                                  child: Image.asset(
                                      'assets/images/placeholder-image.png',
                                      width: 70),
                                  onTap: () {
                                    OpenFile.open(join(filesPath, e.fileName));
                                  },
                                ),
                                subtitle: Wrap(
                                  children: e.tags
                                      .map((t) => Chip(
                                            label: Text(t),
                                            visualDensity: const VisualDensity(
                                                horizontal: 1, vertical: -4),
                                          ))
                                      .toList(),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () async {
                                    // TODO
                                    var k = await showDialog<ActionResult>(
                                        context: context,
                                        builder: (context) {
                                          return EditFileTag(oldFileTag: e);
                                        });

                                    if (k is Changed || k is Deleted) {
                                      _refresh();
                                    }
                                  },
                                ),
                              ))
                          .toList(),
                    )
                  : const Text("No Data"),
            )
          ],
        ),
      ),
    );
  }
}
