import 'package:flutter/foundation.dart';
import 'package:ftm_flutter/repos/driver.dart';

class TagAutocompleteViewModel extends ChangeNotifier {
  final DriverRepo _driverRepo;

  TagAutocompleteViewModel({required DriverRepo driverRepo})
      : _driverRepo = driverRepo;

  Future<List<String>> getAllTags() async {
    final dd = await _driverRepo.getCurrentDriver();

    return _driverRepo.getAllTags(dd.currentDriver);
  }
}
