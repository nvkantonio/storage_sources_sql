import 'dart:async';
import 'package:meta/meta.dart';
import 'package:sqflite_common/sqflite.dart' as sqflite;
import 'package:sqflite_common/sqflite.dart' show Database;
import 'package:storage_sources_core/callback_completer.dart';

import '../../misc.dart';

abstract class DatabaseState {
  DatabaseState() {
    _databaseProcessLocker = DatabaseCallbackCompletersProcesses(openDatabase);
  }

  factory DatabaseState.create(
          FutureOr<Database> Function() openDatabaseImplementationCallback) =>
      DatabaseStateCallback(openDatabaseImplementationCallback);

  late final DatabaseCallbackCompletersProcesses _databaseProcessLocker;

  DatabaseCallbackCompletersProcesses get databaseProcessLocker =>
      _databaseProcessLocker;

  FutureOr<Database> openDatabase();

  Future<R> runInIsolate<R>(FutureOr<R> Function(Database db) callback) async {
    final db = await openDatabase();

    try {
      return await callback(db);
    } finally {
      await db.close();
    }
  }

  Future<R> runInMultiProcessIsolate<R>(
    FutureOr<R> Function(Database db) callback, {
    required Object processLink,
    dynamic equalityArg = const NoArgument(),
  }) async {
    return databaseProcessLocker.runWithDb<R>(
      callback,
      processLink: processLink,
      equalityArg: equalityArg,
    );
  }

  Future<R> runInIsolateOrDirectly<R>(
    FutureOr<R> Function(Database db) callback, [
    Database? database,
  ]) async {
    if (database != null) {
      return callback(database);
    }

    final db = await openDatabase();
    try {
      return await callback(db);
    } catch (e) {
      rethrow;
    } finally {
      await db.close();
    }
  }

  /// Used if database should not be closed in isolates and openDatabase calls
  FutureOr<void> closeDatabase() async {}
}

class DatabaseStateCallback extends DatabaseState {
  DatabaseStateCallback(this.openDatabaseImplementationCallback);

  final FutureOr<Database> Function() openDatabaseImplementationCallback;

  @override
  FutureOr<Database> openDatabase() => openDatabaseImplementationCallback();
}

/// Prevents closing database while stored in memory.
abstract class DatabaseStatePersistentInstance extends DatabaseState {
  Database? _databaseState;

  @protected
  Future<Database> openDatabaseImplementation() =>
      sqflite.databaseFactory.openDatabase(sqflite.inMemoryDatabasePath,
          options: sqflite.OpenDatabaseOptions(singleInstance: true));

  @override
  Future<Database> openDatabase() async {
    try {
      if (_databaseState != null) {
        if (_databaseState!.isOpen == true) {
          return _databaseState!;
        }

        _databaseState = null;
      }

      return _databaseState = await openDatabaseImplementation();
    } catch (e, st) {
      await closeDatabase();
      _databaseState = null;
      throw CanNotOpenDatabase('Can not open database', e, st);
    }
  }

  @override
  Future<void> closeDatabase() async {
    if (_databaseState?.isOpen == true) {
      await _databaseState!.close();
    }
    _databaseState = null;
  }

  @override
  Future<R> runInIsolate<R>(FutureOr<R> Function(Database db) callback) async =>
      await callback(await openDatabase());

  @override
  Future<R> runInIsolateOrDirectly<R>(
    FutureOr<R> Function(Database db) callback, [
    Database? database,
  ]) async =>
      await callback(database ?? await openDatabase());
}

class DatabaseStateInMemory extends DatabaseStatePersistentInstance {
  DatabaseStateInMemory();

  String get dataBasePath => sqflite.inMemoryDatabasePath;

  @override
  Future<Database> openDatabaseImplementation() =>
      sqflite.databaseFactory.openDatabase(sqflite.inMemoryDatabasePath,
          options: sqflite.OpenDatabaseOptions(singleInstance: true));
}
