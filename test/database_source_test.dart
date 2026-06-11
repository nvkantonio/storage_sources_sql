import 'dart:io' as io;

import 'package:test/test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:storage_sources_core/storage_sources_core.dart';

import 'package:storage_sources_sql/src/utils/sql_master_queries.dart';
import 'package:storage_sources_sql/storage_sources_sql.dart';

typedef OkResponse<T> = OkStorageSourceResult<T>;
typedef UndefResponse<T> = UndefinedStorageSourceResult<T>;
typedef ErrorResponse<T> = ErrorStorageSourceResult<T>;

void main() {
  if (!io.Platform.isAndroid || !io.Platform.isIOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  group('A group of databaseSource tests', () {
    final dbState = DatabaseStateInMemory();

    setUp(() async {
      await dbState.openDatabase();
    });

    tearDown(() async {
      await dbState.forceCloseDatabase();
    });

    test('Test db version', () async {
      expect(await dbState.runInIsolate((db) => db.getVersion()), 0);
    });

    test('Test TextValueSqliteStorageSource fetch, update and delete',
        () async {
      const testValue = 'yes-yes-yes';

      final source = TextValueSqliteStorageSource(
        dbState: dbState,
        key: 'test-key',
      );

      expect(await source.isTableExist, false);

      expect(await source.fetchData(), UndefResponse<String?>());

      await source.update(testValue);

      final tableNames = await dbState.runInIsolate((db) {
        return getTableNames(db);
      });

      expect(tableNames, contains(source.tableName));

      expect(await source.isTableExist, true);

      final fetchedData = await source.fetchData();

      expect(fetchedData, OkResponse<String?>(testValue));

      await source.delete();

      expect(await source.fetchData(), UndefResponse<String?>());
    });

    test('Test TextValueConvertibleSqliteStorageSource conversion', () async {
      const testValue = 123;

      final source = TextValueConvertibleSqliteStorageSource<int>(
        dbState: dbState,
        key: 'test-key',
        fromStringConverter: (value) => int.parse(value!),
        toStringConverter: (value) => value.toString(),
      );

      expect(await source.isTableExist, false);

      expect(await source.fetchData(), UndefResponse<int>());

      await source.update(testValue);

      expect(await source.isTableExist, true);

      final fetchedData = await source.fetchData();

      expect(fetchedData, OkResponse<int>(testValue));
    });
  });
}
