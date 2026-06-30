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
    String filePath,
    Database db, [
    List<int>? bytes,
  ]) async {
    final file = io.File(filePath);

    if (!await file.exists()) {
      await file.create(recursive: true);
    }

    if (bytes != null) {
      await file.writeAsBytes(bytes);
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
  Future<int> writeFileAndUpdate(
    String filePath,
    List<int>? bytes, {
    Database? directDb,
  }) async {
    if (dbState is DatabaseStatePersistentInstance) {
      directDb ??= await dbState.openDatabase();
    }

    return dbTableState.runInTableMultiProcess(
      (db) => writeFileAndUpdateDirect(filePath, db, bytes),
      processKey: key,
      equalityArg: 'writeFile:$key:$filePath',
      directDb: directDb,
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
  Future<int> update(io.File newData, {Database? directDb}) async {
    if (dbState is DatabaseStatePersistentInstance) {
      directDb ??= await dbState.openDatabase();
    }

    return dbTableState.runInTableMultiProcess(
      (db) => updateDirect(newData, db),
      processKey: key,
      equalityArg: 'update:$key:${newData.path}',
      directDb: directDb,
    );
  }
}
