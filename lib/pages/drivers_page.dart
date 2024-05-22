import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ftm_flutter/icon/zicon_outline_icons.dart';
import 'package:ftm_flutter/io_manager.dart';

class DriversPage extends HookWidget {
  const DriversPage({super.key});

  @override
  Widget build(BuildContext context) {
    final drivers = useState<List<Driver>>([]);

    useEffect(() {
      drivers.value = getDrivers();
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Drivers"),
      ),
      body: Container(
        padding: const EdgeInsets.all(5),
        child: ListView(
            children: drivers.value
                .map(
                  (e) => ListTile(
                    title: Text(e.name),
                    subtitle: Text(e.path),
                    leading: e.current
                        ? const Text(
                            "CURRENT",
                            style: TextStyle(color: Colors.green),
                          )
                        : const SizedBox.shrink(),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert_rounded),
                      onPressed: () {},
                    ),
                  ),
                )
                .toList()),
      ),
    );
  }
}
