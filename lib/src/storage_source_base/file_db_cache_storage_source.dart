import 'dart:async';

import 'package:meta/meta.dart';
import 'package:storage_sources_core/storage_sources_core.dart';
import 'package:storage_sources_core/callback_completer.dart';

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

  @protected
  final fetchCompletionController = CallbackCompleter<SR<T>>();

  @protected
  final updateCompletionController = CallbackCompleter<int>();

  @protected
  final deleteCompletionController = CallbackCompleter<int>();

  @protected
  Future<SR<T>> fileResultFromPath(String path);

  @protected
  FutureOr<bool> doFileExist(T file);

  @protected
  FutureOr<String> getFilePath(T file);

  @protected
  FutureOr<void> deleteFile(T file);

  @override
  Future<SR<T>> fetchData() => fetchCompletionController.run(_fetchData);

  Future<int> writeFileAndUpdate(T file, List<int> bytes);

  @override
  Future<int> update(T newData) =>
      updateCompletionController.run(() => _update(newData));

  @override
  Future<int> delete([bool doDeleteFile = true]) =>
      deleteCompletionController.run(_delete);

  Future<SR<T>> _fetchData() async {
    try {
      switch (await parent.fetchData()) {
        case NotOkStorageSourceResult<String> result:
          return result.convert<T>();
        case OkStorageSourceResult<String>(:final value):
          return fileResultFromPath(value);
      }
    } catch (e, st) {
      return ErrorStorageSourceResult(e, stackTrace: st);
    }
  }

  Future<int> _update(T newData) async {
    final path = await getFilePath(newData);
    if (await doFileExist(newData)) {
      return await parent.update(path);
    } else {
      throw FileWasNotFoundException(
          'File was not found in path: $path', newData, StackTrace.current);
    }
  }

  Future<int> _delete([bool doDeleteFile = true]) async {
    if (!doDeleteFile) {
      return await parent.delete();
    }

    final String path;

    switch (await parent.fetchData()) {
      case UndefinedStorageSourceResult<String>():
        return await parent.delete();
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

    return await parent.delete();
  }
}
