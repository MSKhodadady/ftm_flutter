import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<Database> getDB() async => openDatabase(
      join(await getDatabasesPath(), 'file_tag.db'),
      onCreate: (db, version) => db.execute(
          "CREATE TABLE fileTag (fileName TEXT, tag TEXT, value TEXT)"),
      version: 1,
    );

const fileTagTable = "fileTag";
const fileNameColumn = "fileName";
const tagColumn = "tag";
