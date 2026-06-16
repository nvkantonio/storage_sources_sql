import 'dart:async';
import 'dart:io' as io;

import 'package:sqflite_common/sqlite_api.dart';
import 'package:storage_sources_core/misc.dart';
import 'package:storage_sources_core/storage_sources_core.dart';

import '../../misc.dart';
import '../../storage_sources_sql.dart';

class IoFileFromDatabasePathStorageSource
    extends FileFromDatabasePathStorageSource<io.File> {
  IoFileFromDatabasePathStorageSource(
      {required super.key, required super.dbTableState});

  Future<int> writeFileAndUpdateDirect(
    io.File file,
    Database db, [
    List<int>? bytes,
  ]) async {
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    } else {
      await file.create();
    }

    return await updateDirect(file, db);
  }

  @override
  Future<bool> doFileExist(io.File file) => file.exists();

  @override
  String getFilePath(io.File file) => file.path;

  @override
  Future<void> deleteFile(io.File file) => file.delete();

  @override
  Future<int> writeFileAndUpdate(io.File file, [List<int>? bytes]) async {
    return dbTableState.runInTableLockAndIsolate(
      callback: (db) => writeFileAndUpdateDirect(file, db, bytes),
      equalityArg: '$runtimeType:update:${file.hashCode}',
    );
  }

  @override
  Future<SR<io.File>> fileResultFromPath(String path) async {
    final file = io.File(path);

    if (!await doFileExist(file)) {
      return OtherErrorStorageSourceResult(
          FileWasNotFoundException(
              'File was not found in path: ${file.path}', file),
          stackTrace: StackTrace.current);
    }

    return OkStorageSourceResult(file);
  }

  @override
  Future<int> update(io.File newData) {
    return dbTableState.runInTableLockAndIsolate(
      callback: (db) => updateDirect(newData, db),
      equalityArg: '$key:update:${newData.path.hashCode}',
    );
  }
}
