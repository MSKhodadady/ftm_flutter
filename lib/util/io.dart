import 'dart:io';

bool isDesktop() => Platform.isLinux || Platform.isWindows || Platform.isLinux;

String getHomePath() {
  return Platform.isAndroid
      ? "/sdcard"
      : Platform.isLinux
          ? Platform.environment['HOME']!
          : Platform.isWindows
              ? Platform.environment['UserProfile']!
              : '';
}
