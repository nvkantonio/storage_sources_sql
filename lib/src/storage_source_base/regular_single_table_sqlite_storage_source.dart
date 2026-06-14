import 'dart:async';
import 'package:meta/meta.dart';
import 'package:sqflite_common/sqflite.dart';
import 'package:storage_sources_core/storage_sources_core.dart';

import '../../misc.dart';
import '../../storage_sources_sql_core.dart';
import '../utils/queries.dart';

abstract class RegularSingleTableSqliteStorageSource<T>
    extends SingleTableSqliteStorageSource<T> {
  RegularSingleTableSqliteStorageSource({
    required this.key,
    required this.dbState,
  }) {
    dbTableState = dbState.createDatabaseTable(
      createTableQuery: createTableQuery,
      tableName: tableName,
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

  String get tableName;

  String get createTableQuery;

  T dataFromDatabaseRow(Map<String, Object?> result);

  Map<String, Object?> databaseRowFromData(T data);

  Future<SR<T>> fetchDataDirect(Database db) async {
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
        await deleteDirect(db);
      }

      return ErrorStorageSourceResult<T>(e, stackTrace: st);
    }
  }

  Future<int> updateDirect(T newData, Database db) async {
    await createTableIfNotExist(db);

    final dbEntry = databaseRowFromData(newData);

    final rowId = await db.insert(
      tableName,
      dbEntry,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return rowId;
  }

  Future<int> deleteDirect(Database db) async {
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

  Future<int> updateDirectManually(
    Map<String, Object?> dbEntry, {
    required Database db,
  }) async {
    await createTableIfNotExist(db);

    final rowId = await db.insert(
      tableName,
      dbEntry,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return rowId;
  }

  @override
  Future<SR<T>> fetchData() {
    return dbTableState.runInTableLockAndIsolate(
      callback: fetchDataDirect,
      equalityArg: '$runtimeType:fetch',
    );
  }

  @override
  Future<int> update(T newData) {
    return dbTableState.runInTableLockAndIsolate(
      callback: (db) => updateDirect(newData, db),
      equalityArg: '$runtimeType:update:${newData.hashCode}',
    );
  }

  @override
  Future<int> delete() {
    return dbTableState.runInTableLockAndIsolate(
      callback: deleteDirect,
      equalityArg: '$runtimeType:delete',
    );
  }

  @protected
  @visibleForTesting
  Future<void> createTableIfNotExist(Database db) async {
    final isTableExist = await dbTableState.checkIsTableExist(db);

    if (!isTableExist) {
      await dbTableState.createTable(db);
    }
  }
}
