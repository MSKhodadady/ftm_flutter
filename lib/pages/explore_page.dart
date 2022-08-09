import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ftm_flutter/data/file_tag.dart';
import 'package:ftm_flutter/files.dart';
import 'package:ftm_flutter/widget/tag_autocomplete.dart';
import 'package:open_file/open_file.dart';
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

    fileTagsFuture = filesList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            //: tag chooser
            TagAutocomplete(
                onSubmitted: (tag) {
                  setState(() {
                    chosenTags = [...chosenTags, tag];
                  });
                },
                chosenTags: chosenTags),
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
                                subtitle: /* SizedBox(
                                  height: 40,
                                  child: ListView */
                                    Wrap(
                                  // scrollDirection: Axis.horizontal,
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
                                  onPressed: () {},
                                ),
                                // ),
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
