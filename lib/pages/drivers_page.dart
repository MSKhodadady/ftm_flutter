import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ftm_flutter/icon/zicon_outline_icons.dart';
import 'package:ftm_flutter/io_manager.dart';

class DriversPage extends HookWidget {
  const DriversPage({super.key});

  void onSetCurrent(Driver e, currentDriver) async {
    await setCurrentDriver(e.name);
    currentDriver.value = e.name;
  }

  @override
  Widget build(BuildContext context) {
    final drivers = useState<List<Driver>>([]);
    final currentDriver = useState('');

    useEffect(() {
      final mf = getMainConf();
      drivers.value = mf.drivers;
      currentDriver.value = mf.currentDriver;

      return;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Drivers"),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 30),
            child: IconButton(
              onPressed: () {
                showDialog<Driver>(
                  context: context,
                  builder: (context) => CreateDriver(drivers.value, (p0) {
                    drivers.value = p0;
                  }),
                );
              },
              icon: const Icon(ZiconOutline.plus),
            ),
          )
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(5),
        child: ListView(
            children: drivers.value
                .map(
                  (e) => ListTile(
                      title: Text(e.name),
                      subtitle: Text(e.path),
                      leading: e.name == currentDriver.value
                          ? const Icon(
                              ZiconOutline.check,
                              color: Colors.green,
                            )
                          : const Icon(
                              Icons.circle_outlined,
                              color: Colors.white,
                            ),
                      trailing: MenuAnchor(
                        menuChildren: [
                          if (e.name != currentDriver.value)
                            MenuItemButton(
                              leadingIcon: const Icon(Icons.check),
                              child: const Text("set current"),
                              onPressed: () => onSetCurrent(e, currentDriver),
                            ),
                          MenuItemButton(
                            leadingIcon: const Icon(ZiconOutline.pen),
                            child: const Text("change name"),
                            onPressed: () {
                              // renameDriver(e.name, newName)

                              showDialog(
                                context: context,
                                builder: (context) => RenameDriver(
                                  oldName: e.name,
                                  onRename: (newName) {
                                    if (e.name != newName) {
                                      renameDriver(e.name, newName);

                                      drivers.value = drivers.value
                                          .map((j) => j.name == e.name
                                              ? Driver(
                                                  name: newName,
                                                  path: j.path,
                                                  type: j.type)
                                              : j)
                                          .toList();

                                      currentDriver.value =
                                          currentDriver.value == e.name
                                              ? newName
                                              : currentDriver.value;
                                    }
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          ),
                          MenuItemButton(
                            leadingIcon: const Icon(ZiconOutline.trash),
                            child: const Text("delete"),
                            onPressed: () {},
                          ),
                        ],
                        builder: (context, controller, child) {
                          return IconButton(
                            icon: const Icon(Icons.more_vert_rounded),
                            onPressed: () {
                              controller.open();
                            },
                          );
                        },
                      )),
                )
                .toList()),
      ),
    );
  }
}

class RenameDriver extends HookWidget {
  const RenameDriver({
    required this.oldName,
    required this.onRename,
    super.key,
  });

  final String oldName;
  final Function(String) onRename;

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController();
    final focusName = useFocusNode();

    final nameError = useState<String?>(null);

    useEffect(() {
      focusName.requestFocus();

      nameController.addListener(() {
        nameError.value = null;
      });
    }, []);

    return AlertDialog(
      content: SizedBox(
          width: 300,
          // height: 100,
          child: TextField(
            decoration: InputDecoration(
                border: const OutlineInputBorder(),
                label: const Text("Enter new name"),
                errorText: nameError.value),
            controller: nameController,
            focusNode: focusName,
          )),
      actions: [
        TextButton(
            onPressed: () {
              final n = nameController.text;

              if (n.isEmpty) return;

              onRename(nameController.text);
            },
            child: const Text("rename"))
      ],
    );
  }
}

class CreateDriver extends HookWidget {
  const CreateDriver(
    this.drivers,
    this.onSetDrivers, {
    super.key,
  });

  final List<Driver> drivers;
  final Function(List<Driver>) onSetDrivers;

  @override
  Widget build(BuildContext context) {
    final nameError = useState<String?>(null);
    final pathError = useState<String?>(null);

    final nameController = useTextEditingController();
    final pathController = useTextEditingController();
    final focusController = useFocusNode();

    final isMounted = useIsMounted();

    useEffect(() {
      focusController.requestFocus();

      nameController.addListener(() {
        nameError.value = null;
      });

      pathController.addListener(() {
        pathError.value = null;
      });

      return;
    }, []);

    return AlertDialog(
      content: SizedBox(
        width: 300,
        height: 200,
        child: Column(
          children: [
            TextField(
              controller: nameController,
              focusNode: focusController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                errorText: nameError.value,
                label: const Text("Enter name"),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: pathController,
                    readOnly: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      label: const Text("path"),
                      errorText: pathError.value,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                TextButton(
                    onPressed: () async {
                      if (isDesktop()) {
                        final result =
                            await FilePicker.platform.getDirectoryPath();

                        if (result != null) {
                          pathController.text = result;
                        }
                      }
                    },
                    child: const Text("Select")),
              ],
            )
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () async {
              if (!isMounted()) return;

              if (nameController.text.isEmpty) {
                nameError.value = "name is empty!";

                return;
              }

              if (pathController.text.isEmpty) {
                pathError.value = "path is empty!";

                return;
              }

              if (drivers
                  .any((element) => element.name == nameController.text)) {
                nameError.value = "another driver with this name";

                return;
              }

              if (drivers
                  .any((element) => element.path == pathController.text)) {
                pathError.value = "another driver with this path";

                return;
              }

              final neoDriver = Driver(
                name: nameController.text,
                path: pathController.text,
                type: 'file',
              );

              await addDriver(neoDriver);

              onSetDrivers([...drivers, neoDriver]);

              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            },
            child: const Text("Add"))
      ],
    );
  }
}
