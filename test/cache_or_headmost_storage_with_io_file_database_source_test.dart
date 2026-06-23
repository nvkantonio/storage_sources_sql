import 'dart:io' as io;

import 'package:storage_sources_core/misc.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path_lib;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:storage_sources_core/storage_sources.dart';

import 'package:storage_sources_sql/storage_sources_sql.dart';

typedef OkResponse<T> = OkStorageSourceResult<T>;
typedef UndefResponse<T> = UndefinedStorageSourceResult<T>;
typedef ErrorResponse<T> = ErrorStorageSourceResult<T>;

void main() {
  if (!io.Platform.isAndroid || !io.Platform.isIOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  group(
      'A group of CacheOrHeadmostStorage with IoFileFromDatabasePathStorageSource tests',
      () {
    final testingPath = path_lib.join(path_lib.current, 'temp_file.txt');
    final testingFile = io.File(testingPath);

    final dbState = DatabaseStateInMemory();
    final dbTableState = PathValueDatabaseTableState(dbState);

    final dbSource = KeyValueSqliteStorageSource(
      key: 'test-key',
      dbTableState: dbTableState,
    );
    final fileSource = IoFileFromDatabasePathStorageSource(
      key: 'test-key',
      dbTableState: dbTableState,
    );

    final storage = CacheOrHeadmostStorage<io.File>(
      cacheSource: fileSource,
      headmostSource: CallbackStorageSource(() => testingFile),
      behavior: CacheOrHeadmostStorageBehavior(
        runTasksImmediately: true,
        runCacheSourceFirst: true,
        doRunSecondIfFirstOk: true,
        deleteCacheOnError: true,
        updateCacheIfNotEqual: true,
      ),
    );

    setUp(() async {
      await dbState.openDatabase();

      if (await testingFile.exists()) {
        await testingFile.delete();
      }
    });

    tearDown(() async {
      dbTableState.clearIsTableExistState();

      if (await testingFile.exists()) {
        await testingFile.delete();
      }

      await dbState.forceCloseDatabase();
    });

    test(
        'Test IoFileFromDatabasePathStorageSource with PathValueSqliteStorageSource manual file create and in data sync',
        () async {
      expect(await testingFile.exists(), false);

      expect(await dbSource.fetchData(), UndefResponse<String>());
      expect(await fileSource.fetchData(), UndefResponse<io.File>());

      expect(await storage.dataStream().toList(), [
        UndefResponse<io.File>(),
        isA<OkResponse<io.File>>(),
        // Because file was not created
        isA<OtherErrorStorageSourceResult<io.File>>(),
      ]);

      expect(await testingFile.exists(), false);

      expect(await dbSource.fetchData(), isA<UndefResponse<String>>());
      expect(await fileSource.fetchData(), isA<UndefResponse<io.File>>());

      await testingFile.create();

      expect(await testingFile.exists(), true);

      expect(await storage.dataStream().toList(), [
        UndefResponse<io.File>(),
        isA<OkResponse<io.File>>(),
      ]);

      expect(await testingFile.exists(), true);

      expect(await dbSource.fetchData(), isA<OkResponse<String>>());
      expect(await fileSource.fetchData(), isA<OkResponse<io.File>>());

      expect(await storage.dataStream().toList(), [
        isA<OkResponse<io.File>>(),
        isA<OkResponse<io.File>>(),
      ]);

      expect(await testingFile.exists(), true);
    });

    test(
        'Test IoFileFromDatabasePathStorageSource with PathValueSqliteStorageSource manual file delete and in data sync',
        () async {
      expect(await testingFile.exists(), false);

      expect(await dbSource.fetchData(), isA<UndefResponse<String>>());
      expect(await fileSource.fetchData(), isA<UndefResponse<io.File>>());

      await fileSource.writeFileAndUpdate(testingFile.path);
      expect(await testingFile.exists(), true);

      expect(await dbSource.fetchData(), isA<OkResponse<String>>());
      expect(await fileSource.fetchData(), isA<OkResponse<io.File>>());

      await testingFile.delete();

      expect(await testingFile.exists(), false);

      expect(await dbSource.fetchData(), isA<OkResponse<String>>());

      expect(await storage.dataStream().toList(), [
        isA<ErrorResponse<io.File>>(),
        isA<OkResponse<io.File>>(),
        // Because file was not created
        isA<OtherErrorStorageSourceResult<io.File>>(),
      ]);

      expect(await testingFile.exists(), false);

      expect(await dbSource.fetchData(), isA<UndefResponse<String>>());
      expect(await fileSource.fetchData(), isA<UndefResponse<io.File>>());
    });
  });
}
