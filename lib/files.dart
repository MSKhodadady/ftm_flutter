import 'dart:io';
import 'package:path/path.dart' as p;

const filesPath = '/storage/emulated/0/FTM';
//: for db and configs
final configFilesPath = p.join(filesPath, '.configs');

Future<void> initFilesDir() async {
  final filesDir = Directory(configFilesPath);

  try {
    await filesDir.create(recursive: true);
  } catch (err) {
    //: TODO
    throw Exception(err);
  }
}
