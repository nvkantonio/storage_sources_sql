import 'dart:async';
import 'package:meta/meta.dart';
import 'package:sqflite_common/sqflite.dart';
import 'package:storage_sources_core/storage_sources_core.dart';
import 'package:storage_sources_core/callback_completer.dart';

import '../../misc.dart';
import '../../storage_sources_sql_core.dart';
import '../utils/queries.dart';

abstract class RegularSingleTableSqliteStorageSource<T>
    extends SingleTableSqliteStorageSource<T> {
  RegularSingleTableSqliteStorageSource({
    required this.key,
    required this.dbState,
  }) {
    dbTableState = DatabaseTableState(
      tableName: tableName,
      createTableQuery: createTableQuery,
      dbState: dbState,
    );
  }

  @override
  final String key;

  @override
  @protected
  final DatabaseState dbState;

  @override
  @protected
  late final DatabaseTableState dbTableState;

  @protected
  final fetchCompletionController = CallbackCompleter<SR<T>>();

  @protected
  final updateCompletionController = CallbackCompleter<int>();

  @protected
  final deleteCompletionController = CallbackCompleter<int>();

  String get createTableQuery;

  @override
  String get tableName;

  T dataFromDatabaseRow(Map<String, Object?> result);

  Map<String, Object?> databaseRowFromData(T data);

  @override
  Future<SR<T>> fetchData() => fetchCompletionController.run(_fetchData);

  @override
  Future<int> update(T newData, [Database? db]) {
    return updateCompletionController.run(() {
      return dbState.runInIsolateOrDirectly((db) {
        return updateNoIsolate(db, newData);
      }, db);
    });
  }

  @override
  Future<int> delete([Database? db]) {
    return deleteCompletionController.run(() {
      return dbState.runInIsolateOrDirectly(deleteNoIsolate, db);
    });
  }

  @visibleForTesting
  Future<int> updateDirect(Map<String, Object?> dbEntry, Database db) async {
    await createTableIfNotExist(db);

    final rowId = await db.insert(
      tableName,
      dbEntry,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return rowId;
  }

  @protected
  @visibleForTesting
  Future<void> createTableIfNotExist(Database db) async {
    final isTableExist = await dbTableState.checkIsTableExist(db);

    if (!isTableExist) {
      await dbTableState.createTable(db);
    }
  }

  Future<SR<T>> _fetchData() async {
    try {
      final db = await dbState.database;

      bool doDeleteKey = false;

      try {
        final isTableExist = await dbTableState.checkIsTableExist(db);

        if (!isTableExist) {
          return UndefinedStorageSourceResult<T>();
        }

        final result = await db.query(
          tableName,
          where: Queries.whereKey,
          whereArgs: [key],
        );

        if (result.isEmpty) {
          return UndefinedStorageSourceResult<T>();
        }

        if (result.length > 1) {
          doDeleteKey = true;
          throw KeyMustBeUnique(
              'Key must be unique. Database holds ${result.length} rows for a key',
              result,
              StackTrace.current);
        }

        return OkStorageSourceResult<T>(dataFromDatabaseRow(result.first));
      } catch (e, st) {
        if (doDeleteKey) {
          await deleteNoIsolate(db);
        }

        return ErrorStorageSourceResult<T>(e, stackTrace: st);
      }
    } finally {
      await dbState.closeDatabase();
    }
  }

  @protected
  Future<int> updateNoIsolate(Database db, T newData) async {
    await createTableIfNotExist(db);

    final dbEntry = databaseRowFromData(newData);

    final rowId = await db.insert(
      tableName,
      dbEntry,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return rowId;
  }

  @protected
  Future<int> deleteNoIsolate(Database db) async {
    final isTableExist = await dbTableState.checkIsTableExist(db);

    if (!isTableExist) {
      return 0;
    }

    final rowsAffectedCount = await db.delete(
      tableName,
      where: Queries.whereKey,
      whereArgs: [key],
    );

    return rowsAffectedCount;
  }
}
