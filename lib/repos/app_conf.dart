import 'package:ftm_flutter/models/app_conf.dart';
import 'package:ftm_flutter/models/driver.dart';
import 'package:ftm_flutter/services/app_conf.dart';

class AppConfRepo {
  final AppConfService appConfService;

  AppConfRepo({required this.appConfService});

  Future<AppConf> getAppConf() {
    return appConfService.readAppConf();
  }

  Future<AppConf> setCurrentDriver(String driverName) {
    return appConfService.setCurrentDriver(driverName);
  }

  Future<AppConf> addDriver(Driver newDriver) {
    return appConfService.addDriver(newDriver);
  }

  Future<AppConf> renameDriver(String driverName, String newName) {
    return appConfService.renameDriver(driverName, newName);
  }

  Future<AppConf> deleteDriver(String driverName) {
    return appConfService.deleteDriver(driverName);
  }
}
