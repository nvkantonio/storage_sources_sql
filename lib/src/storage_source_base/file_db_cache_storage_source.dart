import 'dart:async';

import 'package:meta/meta.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:storage_sources_core/storage_sources_core.dart';

import '../../misc.dart';
import '../../storage_sources_sql.dart';

abstract class _FileFromDatabasePathStorageSource<T>
    extends SingleTableSqliteStorageSourceProxy<T, String,
        PathValueSqliteStorageSource> {}

abstract class FileFromDatabasePathStorageSource<T>
    extends _FileFromDatabasePathStorageSource<T> {
  FileFromDatabasePathStorageSource(
      {required String key, required DatabaseState dbState})
      : parent = PathValueSqliteStorageSource(key: key, dbState: dbState);

  @override
  final PathValueSqliteStorageSource parent;

  Future<int> writeFileAndUpdate(T file, List<int> bytes);

  @protected
  Future<SR<T>> fileResultFromPath(String path);

  @protected
  FutureOr<bool> doFileExist(T file);

  @protected
  FutureOr<String> getFilePath(T file);

  @protected
  FutureOr<void> deleteFile(T file);

  Future<SR<T>> fetchDataDirect(Database db) async {
    try {
      switch (await parent.fetchDataDirect(db)) {
        case NotOkStorageSourceResult<String> result:
          return result.convert<T>();
        case OkStorageSourceResult<String>(:final value):
          return fileResultFromPath(value);
      }
    } catch (e, st) {
      return ErrorStorageSourceResult(e, stackTrace: st);
    }
  }

  Future<int> updateDirect(T newData, Database db) async {
    final path = await getFilePath(newData);

    if (await doFileExist(newData)) {
      return await parent.updateDirect(path, db);
    } else {
      throw FileWasNotFoundException(
          'File was not found in path: $path', newData, StackTrace.current);
    }
  }

  Future<int> deleteDirect(Database db, [bool doDeleteFile = true]) async {
    if (!doDeleteFile) {
      return await parent.deleteDirect(db);
    }

    final String path;

    switch (await parent.fetchDataDirect(db)) {
      case UndefinedStorageSourceResult<String>():
        return 0;
      case ErrorStorageSourceResult<String> result:
        throw result.error;
      case OkStorageSourceResult<String>(:final value):
        path = value;
    }

    switch (await fileResultFromPath(path)) {
      case NotOkStorageSourceResult<T>():
        break;
      case OkStorageSourceResult<T>(:final value):
        await deleteFile(value);
    }

    return await parent.deleteDirect(db);
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
}
