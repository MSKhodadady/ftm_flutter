import 'package:material_ui/material_ui.dart';
import 'package:ftm_flutter/models/app_conf.dart';
import 'package:ftm_flutter/models/driver.dart';

class DriversViewModel extends ChangeNotifier {
  DriversViewModel();

  AppConf? _appConf;

  List<Driver>? get drivers {
    return _appConf?.drivers;
  }

  String? get currentDriver {
    return _appConf?.currentDriver;
  }

  Future<void> _getAppConf() async {
    // TODO:
  }

  Future<void> setCurrentDriver(Driver e) async {
    //
    // TODO:
    await _getAppConf();
  }

  Future<void> onAddDriver(Driver d) async {
    // TODO:
    if (drivers.any((element) => element.name == nameController.text)) {
      nameError.value = "another driver with this name";

      return;
    }

    if (drivers.any((element) => element.path == pathController.text)) {
      pathError.value = "another driver with this path";

      return;
    }
    //
  }

  Future<void> renameDriver(Driver e, String newName) async {
    // TODO:
    if (e.name != newName) {
      DriverService.renameDriver(e.name, newName);

      vm.drivers = vm.drivers
          .map((j) => j.name == e.name
              ? Driver(name: newName, path: j.path, type: j.type)
              : j)
          .toList();

      currentDriver.value =
          currentDriver.value == e.name ? newName : currentDriver.value;
    }
  }

  Future<void> deleteDriver(Driver d) async {
    //: TODO:
  }
}
