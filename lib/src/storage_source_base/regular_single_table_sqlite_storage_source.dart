import 'dart:async';
import 'package:meta/meta.dart';
import 'package:sqflite_common/sqflite.dart';
import 'package:storage_sources_core/storage_sources_core.dart';
import 'package:storage_sources_sql/storage_sources_sql.dart';

import '../../misc.dart';
import '../utils/queries.dart';

abstract class RegularSingleTableSqliteStorageSource<T>
    extends SingleTableSqliteStorageSource<T> {
  RegularSingleTableSqliteStorageSource();

  @override
  String get key;

  @override
  @protected
  KeyValueDatabaseTableState get dbTableState;

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
        dbTableState.tableName,
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
      dbTableState.tableName,
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
      dbTableState.tableName,
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
      dbTableState.tableName,
      dbEntry,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return rowId;
  }

  @override
  Future<SR<T>> fetchData({Database? directDb}) async {
    if (dbState is DatabaseStatePersistentInstance) {
      directDb ??= await dbState.openDatabase();
    }

    return dbTableState.runInTableMultiProcess(
      fetchDataDirect,
      processKey: key,
      equalityArg: 'fetch:$key',
      directDb: directDb,
    );
  }

  @override
  Future<int> update(T newData, {Database? directDb}) async {
    if (dbState is DatabaseStatePersistentInstance) {
      directDb ??= await dbState.openDatabase();
    }

    return dbTableState.runInTableMultiProcess(
      (db) => updateDirect(newData, db),
      processKey: key,
      equalityArg: 'update:$key:${newData.hashCode}',
      directDb: directDb,
    );
  }

  @override
  Future<int> delete({Database? directDb}) async {
    if (dbState is DatabaseStatePersistentInstance) {
      directDb ??= await dbState.openDatabase();
    }

    return dbTableState.runInTableMultiProcess(
      deleteDirect,
      processKey: key,
      equalityArg: 'delete:$key',
      directDb: directDb,
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
