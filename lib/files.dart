import 'dart:io';
import 'package:path/path.dart' as p;

const mainFolderName = "FTM";

String getLinuxHome() {
  return Platform.environment['HOME']!;
}

String getWindowsHomePath() {
  return Platform.environment['UserProfile']!;
}

String filesPath() {
  if (Platform.isAndroid) {
    return '/storage/emulated/0/$mainFolderName';
  } else if (Platform.isLinux) {
    return '${getLinuxHome()}/$mainFolderName';
  } else if (Platform.isWindows) {
    return p.join(getWindowsHomePath(), mainFolderName);
  } else {
    throw Error();
  }
}

//: for db and configs
final configFilesPath = p.join(filesPath(), '.configs');

Future<void> initFilesDir() async {
  final configFilesDir = Directory(configFilesPath);

  try {
    await configFilesDir.create(recursive: true);
  } catch (err) {
    //: TODO
    throw Exception(err);
  }
}

String homePath() {
  return Platform.isAndroid
      ? "/sdcard"
      : Platform.isLinux
          ? getLinuxHome()
          : Platform.isWindows
              ? getWindowsHomePath()
              : '';
}
