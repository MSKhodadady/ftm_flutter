import 'dart:convert';
import 'package:ftm_flutter/models/driver.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:ftm_flutter/util/io.dart';

const _mainDriverName = 'FTM';

class AppConf {
  static final _mainConfDriversKey = 'drivers';
  static final _currentDriverKey = 'current';

  final List<Driver> drivers;
  final String currentDriver;

  AppConf(this.drivers, this.currentDriver);

  factory AppConf.fromJson(String mc) {
    try {
      final mfMap = jsonDecode(mc);

      final drivers = (mfMap[_mainConfDriversKey] as List<dynamic>)
          .map<Driver?>((e) {
            try {
              var res = Driver.fromMap(e);
              return res;
            } catch (e) {
              return null;
            }
          })
          .where((e) => e != null)
          .map<Driver>((e) => e!)
          .toList();

      if (drivers.isEmpty) {
        return AppConf.appStarter();
      }

      final currentDriverInJson = mfMap[_currentDriverKey] as String;
      final currentDriver = drivers.firstWhereOrNull(
                  (element) => element.name == currentDriverInJson) ==
              null
          ? drivers[0].name
          : currentDriverInJson;

      return AppConf(drivers, currentDriver);
    } catch (e) {
      return AppConf.appStarter();
    }
  }

  factory AppConf.appStarter() {
    final mainDriver = Driver(
      name: _mainDriverName,
      path: p.join(getHomePath(), _mainDriverName),
      type: 'file',
    );

    return AppConf([mainDriver], _mainDriverName);
  }

  Map<String, dynamic> toMap() {
    return {
      _mainConfDriversKey: drivers.map((e) => e.toMap()).toList(),
      _currentDriverKey: currentDriver,
    };
  }
}
