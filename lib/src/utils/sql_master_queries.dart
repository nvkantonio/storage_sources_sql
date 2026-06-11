import 'dart:async';
import 'package:sqflite_common/utils/utils.dart';
import 'package:sqflite_common/sqflite.dart';

Future<bool> tableExists(DatabaseExecutor db, String table) async {
  var count = firstIntValue(
    await db.query(
      'sqlite_master',
      columns: ['COUNT(*)'],
      where: 'type = ? AND name = ?',
      whereArgs: ['table', table],
    ),
  );
  return count != null && count > 0;
}

Future<List<String>> getTableNames(DatabaseExecutor db) async {
  var tableNames = (await db.query(
    'sqlite_master',
    where: 'type = ?',
    whereArgs: ['table'],
  )).map((row) => row['name'] as String).toList(growable: false)..sort();
  return tableNames;
}
