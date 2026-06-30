import 'dart:async';
import 'package:meta/meta.dart';
import 'package:sqflite_common/sqflite.dart';
import 'package:storage_sources_core/callback_completer.dart';

class DatabaseCallbackCompletersProcesses extends CallbackCompletersProcesses {
  DatabaseCallbackCompletersProcesses(this.openDatabaseImplementationCallback);

  FutureOr<Database>? _database;

  final FutureOr<Database> Function() openDatabaseImplementationCallback;

  @visibleForTesting
  FutureOr<Database>? get database => _database;

  Future<R> runWithDb<R extends dynamic>(
    FutureOr<R> Function(Database db) callback, {
    required Object processLink,
    equalityArg = const NoArgument(),
  }) async {
    final Database db;

    switch (_database) {
      case Database database when database.isOpen:
        db = database;
      case Database database when !database.isOpen:
      case null:
        _database = openDatabaseImplementationCallback();
        db = await _database!;
        _database = db;
      default:
        db = await _database!;
    }

    return run(
      () => callback(db),
      processLink: processLink,
      equalityArg: equalityArg,
    ).whenComplete(
      () {
        if (completersHashMap.isEmpty) {
          switch (_database) {
            case Database database when database.isOpen:
              database.close();
              _database = null;
            case Database database when !database.isOpen:
              _database = null;
            default:
              break;
          }
        }
      },
    );
  }
}
