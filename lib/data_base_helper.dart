import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;
  Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'pdf_database.db');
    return await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute('''
        CREATE TABLE pdfs (
          id INTEGER PRIMARY KEY,
          path TEXT
        )
      ''');
    });
  }

  Future<void> insertPDFPath(String path) async {
    final db = await database;
    await db.insert('pdfs', {'path': path});
  }

  Future<List<String>> getPDFPaths(int offset, int limit) async {
    final db = await database;

    final query = 'SELECT path FROM pdfs LIMIT $limit OFFSET $offset';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query);

    return List.generate(maps.length, (i) {
      return maps[i]['path'];
    });
  }


  Future<void> clearTable() async {
    final db = await database;
    await db.delete('pdfs');
  }
}
