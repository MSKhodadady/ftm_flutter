import 'dart:io';

const filesPath = '/storage/emulated/0/FTM';

Future<void> initFilesDir() async {
  final filesDir = Directory(filesPath);

  try {
    await filesDir.create();
  } catch (err) {
    //: TODO
    throw Exception(err);
  }
}
