import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ftm_flutter/widget/chosen_tag_list.dart';
import 'package:ftm_flutter/widget/tag_autocomplete.dart';

class AddTagFiles extends HookWidget {
  const AddTagFiles({super.key});

  @override
  Widget build(BuildContext context) {
    final chosenTags = useState<List<String>>([]);

    return AlertDialog(
      actions: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pop(chosenTags.value);
            },
            child: const Text("Done"))
      ],
      content: SizedBox(
        width: 300,
        height: 300,
        child: ListView(
          children: [
            TagAutocomplete(
              onSubmitted: (tag) {
                chosenTags.value = [...chosenTags.value, tag];
              },
              chosenTags: chosenTags.value,
            ),
            const SizedBox(height: 13),
            ChosenTagList(
              chosenTags: chosenTags.value,
              onDeleted: (t) {
                chosenTags.value =
                    chosenTags.value.where((element) => element != t).toList();
              },
            )
          ],
        ),
      ),
    );
  }
}
