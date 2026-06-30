import 'dart:io' as io;

import 'package:test/test.dart';
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

  group('A group of ParsedTextValueSqliteStorageSource tests', () {
    final dbState = DatabaseStateInMemory();
    final dbTableState = TextValueDatabaseTableState(dbState);

    setUp(() async {
      await dbState.openDatabase();
    });

    tearDown(() async {
      dbTableState.clearIsTableExistState();
      await dbState.closeDatabase();
    });

    test(
      'Test ParsedTextValueSqliteStorageSource fetch, update and delete and in sync',
      () async {
        const testValue = 123;

        final originalSource = TextValueSqliteStorageSource(
          key: 'test-key',
          dbTableState: dbTableState,
        );

        final source = ParsedTextValueSqliteStorageSource(
          parent: originalSource,
          fromStringConverter: (value) => int.parse(value!),
          toStringConverter: (value) => value.toString(),
        );

        expect(await source.fetchData(), UndefResponse<int>());
        expect(await originalSource.fetchData(), UndefResponse<String?>());

        await source.update(testValue);

        expect(await source.fetchData(), OkResponse<int>(testValue));
        expect(await originalSource.fetchData(),
            OkResponse<String?>(testValue.toString()));

        await source.delete();

        expect(await source.fetchData(), UndefResponse<int>());
        expect(await originalSource.fetchData(), UndefResponse<String?>());
      },
    );
  });
}
