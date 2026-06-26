import 'dart:async';
import 'package:sqflite_common/sqflite.dart';
import 'package:storage_sources_core/callback_completer.dart';

import '../../misc.dart';

abstract class DatabaseState {
  DatabaseState() {
    _databaseProcessLocker = CallbackCompletersProcesses();
  }

  factory DatabaseState.create(
          FutureOr<Database> Function() openDatabaseImplementationCallback) =>
      DatabaseStateCallback(openDatabaseImplementationCallback);

  late final CallbackCompletersProcesses _databaseProcessLocker;

  CallbackCompletersProcesses get databaseProcessLocker =>
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
class DatabaseStateInMemory extends DatabaseState {
  DatabaseStateInMemory();

  String get dataBasePath => inMemoryDatabasePath;

  Database? _databaseState;

  @override
  Future<Database> openDatabase() async {
    try {
      if (_databaseState != null) {
        if (_databaseState!.isOpen == true) {
          return _databaseState!;
        }

        _databaseState = null;
      }

      return _databaseState = await _openInMemoryDatabase();
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

  Future<Database> _openInMemoryDatabase() =>
      databaseFactory.openDatabase(inMemoryDatabasePath);
}
