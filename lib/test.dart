// ignore_for_file: avoid_print
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

void printDirectories() async {
  print("getApplicationDocumentsDirectory");
  print(await getApplicationDocumentsDirectory());
  // '/data/user/0/om.msk.ftm_flutter/app_flutter'

  print("getApplicationSupportDirectory");
  print(await getApplicationSupportDirectory());
  // '/data/user/0/om.msk.ftm_flutter/files'

  // print("getDownloadsDirectory")
  // print(await getDownloadsDirectory());
  // not on android

  print("getExternalCacheDirectories");
  print(await getExternalCacheDirectories());
  // [
  //    Directory: '/storage/emulated/0/Android/data/om.msk.ftm_flutter/cache',
  //    Directory: '/storage/1907-0A11/Android/data/om.msk.ftm_flutter/cache'
  // ]

  print("getExternalStorageDirectory");
  print(await getExternalStorageDirectory());
  // '/storage/emulated/0/Android/data/om.msk.ftm_flutter/files'

  // print("getLibraryDirectory");
  // print(await getLibraryDirectory());
  // getLibraryPath is not supported on Android

  print("getTemporaryDirectory");
  print(await getTemporaryDirectory());
  // '/data/user/0/om.msk.ftm_flutter/cache'

  print("getDatabasesPath");
  print(await getDatabasesPath());
  // '/data/user/0/com.msk.ftm_flutter/databases'

  // print("home dir");
  // print(getHomeDirectory().path);
}
