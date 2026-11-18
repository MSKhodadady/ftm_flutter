import 'package:ftm_flutter/repos/app_conf.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ftm_flutter/models/app_conf.dart';
import 'package:ftm_flutter/models/driver.dart';

class DriversViewModel extends ChangeNotifier {
  final AppConfRepo _appConfRepo;
  DriversViewModel({required AppConfRepo appConfRepo})
      : _appConfRepo = appConfRepo;

  AppConf? _appConf;

  List<Driver>? get drivers {
    return _appConf?.drivers;
  }

  String? get currentDriver {
    return _appConf?.currentDriver;
  }

  Future<AppConf> getAppConf() async {
    if (_appConf == null) {
      _appConf = await _appConfRepo.getAppConf();
      notifyListeners();
    }

    return _appConf!;
  }

  Future<void> setCurrentDriver(Driver e) async {
    _appConf = await _appConfRepo.setCurrentDriver(e.name);

    notifyListeners();
  }

  Future<void> onAddDriver(Driver d) async {
    _appConf = await _appConfRepo.addDriver(d);

    notifyListeners();
  }

  Future<void> renameDriver(Driver d, String newName) async {
    _appConf = await _appConfRepo.renameDriver(d.name, newName);

    notifyListeners();
  }

  Future<void> deleteDriver(Driver d) async {
    _appConf = await _appConfRepo.deleteDriver(d.name);

    notifyListeners();
  }
}
