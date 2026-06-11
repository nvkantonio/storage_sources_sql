import 'dart:async';
import 'package:meta/meta.dart';
import 'package:sqflite_common/sqflite.dart';

import '../../misc.dart';

abstract class DatabaseState {
  DatabaseState();

  factory DatabaseState.withPath(String dataBasePath) =>
      DatabaseStateOpenWithPath(dataBasePath);

  factory DatabaseState.withCallback(
    FutureOr<Database> Function() openDatabaseImplementationCallback,
  ) =>
      DatabaseStateOpenWithCallback(openDatabaseImplementationCallback);

  Database? _databaseState;

  /// This getter does not close db connection automatically
  FutureOr<Database> get database {
    if (_databaseState?.isOpen == true) {
      return _databaseState!;
    } else {
      return openDatabase();
    }
  }

  @protected
  FutureOr<Database> get openDatabaseImplementation;

  Future<Database> openDatabase() async {
    try {
      if (_databaseState != null) {
        if (_databaseState!.isOpen == true) {
          return _databaseState!;
        }

        _databaseState = null;
      }

      return _databaseState = await openDatabaseImplementation;
    } catch (e, st) {
      await forceCloseDatabase();
      throw CanNotOpenDatabase('Can not open database', e, st);
    }
  }

  FutureOr<void> closeDatabase();

  Future<void> forceCloseDatabase() async {
    if (_databaseState?.isOpen == true) {
      await _databaseState!.close();
    }
    _databaseState = null;
  }

  Future<R> runInMainDb<R>(FutureOr<R> Function(Database db) callback) async {
    return await callback(await database);
  }

  Future<R> runInIsolate<R>(FutureOr<R> Function(Database db) callback) async {
    final db = await openDatabaseImplementation;

    try {
      return await callback(db);
    } finally {
      await db.close();
    }
  }

  Future<R> runInIsolateOrDirectly<R>(
    FutureOr<R> Function(Database db) callback, [
    Database? database,
  ]) async {
    if (database != null) {
      return callback(database);
    }

    final db = await openDatabaseImplementation;
    try {
      return await callback(db);
    } finally {
      await db.close();
    }
  }
}

class DatabaseStateOpenWithCallback extends DatabaseState {
  DatabaseStateOpenWithCallback(this.openDatabaseImplementationCallback);

  final FutureOr<Database> Function() openDatabaseImplementationCallback;

  @override
  FutureOr<Database> get openDatabaseImplementation =>
      openDatabaseImplementationCallback();

  @override
  Future<void> closeDatabase() => forceCloseDatabase();
}

class DatabaseStateOpenWithPath extends DatabaseState {
  DatabaseStateOpenWithPath(this.dataBasePath);

  final String dataBasePath;

  @override
  @protected
  Future<Database> get openDatabaseImplementation =>
      databaseFactory.openDatabase(dataBasePath);

  @override
  Future<void> closeDatabase() => forceCloseDatabase();
}

/// Prevents closing database while stored in memory.
/// Closes with [forceCloseDatabase] only
class DatabaseStateInMemory extends DatabaseState {
  DatabaseStateInMemory();

  String get dataBasePath => inMemoryDatabasePath;

  @override
  @protected
  Future<Database> get openDatabaseImplementation =>
      databaseFactory.openDatabase(dataBasePath);

  @override
  Future<void> closeDatabase() async {}

  @override
  Future<R> runInIsolate<R>(FutureOr<R> Function(Database db) callback) async =>
      runInMainDb(callback);

  @override
  Future<R> runInIsolateOrDirectly<R>(
    FutureOr<R> Function(Database db) callback, [
    Database? database,
  ]) =>
      runInMainDb(callback);
}
