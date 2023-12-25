import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:open_file_plus/src/platform/linux.dart' as linux;

class FileLeading extends StatelessWidget {
  const FileLeading({super.key, required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context) {
    void Function() openFile(String filePath) {
      if (Platform.isLinux) {
        var k = filePath
            .replaceAll("'", "\\'")
            .replaceAll('(', '\\(')
            .replaceAll(')', '\\)');

        return () {
          linux.system(['xdg-open', k]);
        };
      } else {
        return () {
          OpenFile.open(filePath);
        };
      }
    }

    Widget defaultOpen(IconData icon) {
      return IconButton(onPressed: openFile(filePath), icon: Icon(icon));
    }

    if (FileSystemEntity.isFileSync(filePath)) {
      var mimeType = lookupMimeType(filePath);

      if (mimeType == null) {
        return defaultOpen(Icons.feed_outlined);
      } else if (mimeType.startsWith('image/')) {
        return InkWell(
            onTap: openFile(filePath),
            child: () {
              if (filePath.endsWith('.svg')) {
                return defaultOpen(Icons.image);
              } else {
                return Image.file(
                  File(filePath),
                  width: 100,
                  height: 100,
                );
              }
            }());
      } else if (mimeType.startsWith('audio/')) {
        return defaultOpen(Icons.music_note_outlined);
      } else if (mimeType.startsWith('video/')) {
        return defaultOpen(Icons.video_file);
      } else if (mimeType.startsWith('application/pdf')) {
        return defaultOpen(Icons.picture_as_pdf);
      } else {
        return defaultOpen(Icons.feed_outlined);
      }
    } else {
      return const Icon(Icons.folder);
    }
  }
}
