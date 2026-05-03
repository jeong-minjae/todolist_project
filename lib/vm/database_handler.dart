import 'package:myprogect/model/todolist.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHandler {
  static const _dbName = 'todolist_clean.db';
  static const _dbVersion = 1;
  static Database? _database;

  Future<Database> initalizeDB() async {
    if (_database != null) return _database!;

    final path = await getDatabasesPath();

    _database = await openDatabase(
      join(path, _dbName),
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          create table todolist(
            seq integer primary key autoincrement,
            detail text not null,
            date text,
            addDetail text not null,
            import text not null,
            ischeck integer not null default 0,
            sortOrder integer
          )
        ''');
      },
    );

    return _database!;
  }

  Future<List<Todolist>> queryTodolist() async {
    final db = await initalizeDB();
    final queryResult = await db.query(
      'todolist',
      orderBy: 'substr(date, 1, 10) asc, coalesce(sortOrder, seq) asc, seq asc',
    );

    return queryResult.map((e) => Todolist.fromMap(e)).toList();
  }

  Future<int> insertTodolist(Todolist todolist) async {
    final db = await initalizeDB();
    final result = await db.insert('todolist', {
      'detail': todolist.detail,
      'date': todolist.date,
      'addDetail': todolist.addDetail,
      'import': todolist.import,
      'ischeck': todolist.ischeck ?? 0,
      'sortOrder': todolist.sortOrder,
    });

    if (todolist.sortOrder == null) {
      await db.update(
        'todolist',
        {'sortOrder': result},
        where: 'seq = ?',
        whereArgs: [result],
      );
    }

    return result;
  }

  Future<int> updateTodolist(Todolist todolist) async {
    if (todolist.seq == null) return 0;

    final db = await initalizeDB();
    return db.update(
      'todolist',
      {
        'detail': todolist.detail,
        'date': todolist.date,
        'addDetail': todolist.addDetail,
        'import': todolist.import,
        'ischeck': todolist.ischeck ?? 0,
        'sortOrder': todolist.sortOrder,
      },
      where: 'seq = ?',
      whereArgs: [todolist.seq],
    );
  }

  Future<void> deleteTodolist(int seq) async {
    final db = await initalizeDB();
    await db.delete('todolist', where: 'seq = ?', whereArgs: [seq]);
  }

  Future<void> updateTodoOrder(List<Todolist> todolists) async {
    final db = await initalizeDB();
    final batch = db.batch();

    for (var i = 0; i < todolists.length; i++) {
      final seq = todolists[i].seq;
      if (seq == null) continue;

      batch.update(
        'todolist',
        {'sortOrder': i + 1},
        where: 'seq = ?',
        whereArgs: [seq],
      );
    }

    await batch.commit(noResult: true);
  }
}
