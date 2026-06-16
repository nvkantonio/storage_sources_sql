import 'dart:io' as io;

import 'package:test/test.dart';
import 'package:path/path.dart' as path_lib;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:storage_sources_core/storage_sources_core.dart';

import 'package:storage_sources_sql/storage_sources_sql.dart';

typedef OkResponse<T> = OkStorageSourceResult<T>;
typedef UndefResponse<T> = UndefinedStorageSourceResult<T>;
typedef ErrorResponse<T> = ErrorStorageSourceResult<T>;

void main() {
  if (!io.Platform.isAndroid || !io.Platform.isIOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  group('A group of IoFileFromDatabasePathStorageSource tests', () {
    final testingPath = path_lib.join(path_lib.current, 'temp_file.txt');
    final testingFile = io.File(testingPath);

    final dbState = DatabaseStateInMemory();
    final dbTableState = PathValueDatabaseTableState(dbState);

    final dbSource = PathValueSqliteStorageSource(
      key: 'test-key',
      dbTableState: dbTableState,
    );
    final fileSource = IoFileFromDatabasePathStorageSource(
      key: 'test-key',
      dbTableState: dbTableState,
    );

    setUp(() async {
      await dbState.openDatabase();

      if (await testingFile.exists()) {
        await testingFile.delete();
      }
    });

    tearDown(() async {
      dbTableState.clearIsTableExistState();

      await dbState.forceCloseDatabase();

      if (await testingFile.exists()) {
        await testingFile.delete();
      }
    });

    test(
        'Test IoFileFromDatabasePathStorageSource and PathValueSqliteStorageSource fetch, writeFileAndUpdate and delete and in data sync',
        () async {
      expect(await testingFile.exists(), false);

      expect(await fileSource.dbTableStatePublic.isTableExist, false);

      expect(await dbSource.fetchData(), UndefResponse<String>());
      expect(await fileSource.fetchData(), UndefResponse<io.File>());

      await fileSource.writeFileAndUpdate(testingFile);

      expect(await dbSource.dbTableStatePublic.isTableExist, true);
      expect(await fileSource.dbTableStatePublic.isTableExist, true);

      expect(await dbSource.fetchData(), OkResponse<String>(testingPath));
      expect(await fileSource.fetchData(), isA<OkResponse<io.File>>());

      expect(await testingFile.exists(), true);

      await fileSource.delete();
      expect(await testingFile.exists(), false);

      expect(await dbSource.fetchData(), UndefResponse<String>());
      expect(await fileSource.fetchData(), UndefResponse<io.File>());
    });

    test(
        'Test IoFileFromDatabasePathStorageSource with manual file removal and PathValueSqliteStorageSource in sync',
        () async {
      expect(await testingFile.exists(), false);

      await fileSource.writeFileAndUpdate(testingFile);

      expect(await dbSource.fetchData(), OkResponse<String>(testingPath));
      expect(await fileSource.fetchData(), isA<OkResponse<io.File>>());

      expect(await testingFile.exists(), true);

      await testingFile.delete();

      expect(await testingFile.exists(), false);

      expect(await fileSource.fetchData(), isA<ErrorResponse<io.File>>());
      expect(await dbSource.fetchData(), OkResponse<String>(testingPath));

      expect(await fileSource.fetchData(), isA<ErrorResponse<io.File>>());
      expect(await dbSource.fetchData(), OkResponse<String>(testingPath));

      await fileSource.delete();

      expect(await dbSource.fetchData(), UndefResponse<String>());
      expect(await fileSource.fetchData(), UndefResponse<io.File>());
    });

    test(
        'Test IoFileFromDatabasePathStorageSource with manual file creation using update and PathValueSqliteStorageSource in sync',
        () async {
      expect(await testingFile.exists(), false);
      expect(await dbSource.fetchData(), UndefResponse<String>());
      expect(await fileSource.fetchData(), UndefResponse<io.File>());

      await testingFile.create();

      expect(await testingFile.exists(), true);

      await fileSource.update(testingFile);

      expect(await testingFile.exists(), true);

      expect(await dbSource.fetchData(), OkResponse<String>(testingPath));
      expect(await fileSource.fetchData(), isA<OkResponse<io.File>>());
    });

    test(
        'Test IoFileFromDatabasePathStorageSource with manual file creation using writeFileAndUpdate and PathValueSqliteStorageSource in sync',
        () async {
      expect(await testingFile.exists(), false);
      expect(await dbSource.fetchData(), UndefResponse<String>());
      expect(await fileSource.fetchData(), UndefResponse<io.File>());

      await testingFile.create();

      expect(await testingFile.exists(), true);

      await fileSource.writeFileAndUpdate(testingFile);

      expect(await testingFile.exists(), true);

      expect(await dbSource.fetchData(), OkResponse<String>(testingPath));
      expect(await fileSource.fetchData(), isA<OkResponse<io.File>>());
    });
  });
}
