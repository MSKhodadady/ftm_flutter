import 'dart:io';
import 'package:path/path.dart' as p;

const mainFolderName = "FTM";

const filesPath = '/storage/emulated/0/$mainFolderName';
//: for db and configs
final configFilesPath = p.join(filesPath, '.configs');

Future<void> initFilesDir() async {
  final configFilesDir = Directory(configFilesPath);

  try {
    await configFilesDir.create(recursive: true);
  } catch (err) {
    //: TODO
    throw Exception(err);
  }
}
