import 'dart:async';
import 'package:meta/meta.dart';
import 'package:sqflite_common/sqflite.dart';
import 'package:storage_sources_core/callback_completer.dart';

import '../utils/queries.dart';
import '../utils/sql_master_queries.dart';

import '../../storage_sources_sql_core.dart';
import '../../misc.dart';

abstract interface class DatabaseTableStatePublic {
  CallbackCompletersProcesses get tableProcessLocker;

  FutureOr<bool> get isTableExist;
  String get tableName;

  FutureOr<bool> checkIsTableExist();

  Future<R> runInTableLock<R>(
    Future<R> Function() callback, {
    String? equalityArg,
  });

  Future<R> runInTableLockAndIsolate<R>({
    required FutureOr<R> Function(Database db) callback,
    dynamic equalityArg = const NoArgument(),
  });

  void clearIsTableExistState();
}

abstract class DatabaseTableStateBase implements DatabaseTableStatePublic {
  String get createTableQuery;

  DatabaseState get dbState;

  @protected
  bool? isTableExistState;

  @override
  FutureOr<bool> get isTableExist => checkIsTableExist();

  @override
  CallbackCompletersProcesses get tableProcessLocker =>
      dbState.databaseProcessLocker;

  @override
  Future<R> runInTableLock<R>(
    Future<R> Function() callback, {
    dynamic equalityArg = const NoArgument(),
  }) async {
    return tableProcessLocker.run<R>(
      callback,
      processLink: tableName,
      equalityArg: equalityArg,
    );
  }

  @override
  Future<R> runInTableLockAndIsolate<R>({
    required FutureOr<R> Function(Database db) callback,
    String? processKey,
    dynamic equalityArg = const NoArgument(),
  }) {
    return tableProcessLocker.run<R>(
      () => dbState.runInIsolate<R>(callback),
      processLink: processKey != null ? '$tableName:$processKey' : tableName,
      equalityArg: equalityArg,
    );
  }

  Future<void> createTable([Database? db]) async {
    await dbState.runInIsolateOrDirectly(_createTableNoIsolate, db);
  }

  Future<void> deleteTable([Database? db]) async {
    await dbState.runInIsolateOrDirectly(_deleteTableNoIsolate, db);
  }

  Future<void> deleteTableRows([Database? db]) async {
    await dbState.runInIsolateOrDirectly(_deleteTableRowsNoIsolate, db);
  }

  @override
  FutureOr<bool> checkIsTableExist([Database? db]) {
    if (isTableExistState != null) return isTableExistState!;

    return dbState.runInIsolateOrDirectly(_checkIsTableExistNoIsolate, db);
  }

  @override
  void clearIsTableExistState() => isTableExistState = null;

  FutureOr<bool> _checkIsTableExistNoIsolate(Database db) {
    if (isTableExistState != null) return isTableExistState!;

    return tableExists(db, tableName);
  }

  Future<void> _createTableNoIsolate(Database db) async {
    await db.execute(createTableQuery);

    isTableExistState = null;
    final isTableExist = isTableExistState = await checkIsTableExist(db);

    if (!isTableExist) {
      throw CanNotCreateTable('Can not create table', null, StackTrace.current);
    }
  }

  Future<void> _deleteTableNoIsolate(Database db) async {
    await db.execute(Queries.dropTableQuery(tableName));
    isTableExistState = false;
  }

  Future<void> _deleteTableRowsNoIsolate(Database db) async {
    await db.delete(tableName);
  }
}

final class DatabaseTableState extends DatabaseTableStateBase {
  DatabaseTableState({
    required this.createTableQuery,
    required this.dbState,
    required this.tableName,
  });

  @override
  final String createTableQuery;

  @override
  final DatabaseState dbState;

  @override
  final String tableName;
}
