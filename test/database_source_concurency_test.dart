import 'dart:io' as io;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:storage_sources_core/storage_sources_core.dart';
import 'package:test/test.dart';

import 'package:storage_sources_sql/storage_sources_sql.dart';

typedef SrOk<T> = OkStorageSourceResult<T>;
typedef SrUndef<T> = UndefinedStorageSourceResult<T>;
typedef SrError<T> = ErrorStorageSourceResult<T>;

class TestException implements Exception {
  const TestException([this.source, this.stacktrace]);

  final dynamic source;
  final dynamic stacktrace;
}

Future<dynamic> runTestFutureException(Function() callback) =>
    Future<dynamic>(callback).catchError(
      TestException.new,
    );

final isNotTextException = isNot(isA<TestException>());

void main() {
  if (!io.Platform.isAndroid || !io.Platform.isIOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  group('A group of databaseSource tests', () {
    final dbState = DatabaseStateInMemory();
    final dbTableState = TextValueDatabaseTableState(dbState);

    final source1 = TextValueSqliteStorageSource(
      key: 'test-key',
      dbTableState: dbTableState,
    );

    final source2 = TextValueSqliteStorageSource(
      key: 'test-key',
      dbTableState: dbTableState,
    );

    setUp(() async {
      await dbState.openDatabase();
    });

    tearDown(() async {
      dbTableState.clearIsTableExistState();
      await dbState.closeDatabase();
    });

    test('Test single SqliteStorageSource concurrent operations same key',
        () async {
      const testValue = 'yes-yes-yes';

      final fetchResult1 = runTestFutureException(source1.fetchData);
      final fetchResult2 = runTestFutureException(source1.fetchData);

      expect(await fetchResult1, isNotTextException);
      expect(await fetchResult2, isNotTextException);
      expect(
          await runTestFutureException(source1.fetchData), isNotTextException);

      final updateResult1 =
          runTestFutureException(() => source1.update(testValue));
      final updateResult2 =
          runTestFutureException(() => source1.update(testValue));

      expect(await updateResult1, isNotTextException);
      expect(await updateResult2, isNotTextException);
      expect(await runTestFutureException(() => source1.update(testValue)),
          isNotTextException);

      final deleteResult1 = runTestFutureException(() => source1.delete());
      final deleteResult2 = runTestFutureException(() => source1.delete());

      expect(await deleteResult1, isNotTextException);
      expect(await deleteResult2, isNotTextException);
      expect(await runTestFutureException(() => source1.delete()),
          isNotTextException);
    });

    test('Test multiple SqliteStorageSource concurrent operations same key',
        () async {
      const testValue = 'yes-yes-yes';

      final fetchResult1 = runTestFutureException(source1.fetchData);
      final fetchResult2 = runTestFutureException(source2.fetchData);

      expect(await fetchResult1, isNotTextException);
      expect(await fetchResult2, isNotTextException);
      expect(
          await runTestFutureException(source1.fetchData), isNotTextException);

      final updateResult1 =
          runTestFutureException(() => source1.update(testValue));
      final updateResult2 =
          runTestFutureException(() => source2.update(testValue));

      expect(await updateResult1, isNotTextException);
      expect(await updateResult2, isNotTextException);
      expect(await runTestFutureException(() => source1.update(testValue)),
          isNotTextException);

      final deleteResult1 = runTestFutureException(() => source1.delete());
      final deleteResult2 = runTestFutureException(() => source2.delete());

      expect(await deleteResult1, isNotTextException);
      expect(await deleteResult2, isNotTextException);
      expect(await runTestFutureException(() => source1.delete()),
          isNotTextException);
    });

    test(
        'Test multiple SqliteStorageSource concurrent operations different key',
        () async {
      const testValue = 'yes-yes-yes';
      final fetchResult1 = runTestFutureException(source1.fetchData);
      final fetchResult2 = runTestFutureException(source2.fetchData);

      expect(await fetchResult1, isNotTextException);
      expect(await fetchResult2, isNotTextException);
      expect(
          await runTestFutureException(source1.fetchData), isNotTextException);

      final updateResult1 =
          runTestFutureException(() => source1.update(testValue));
      final updateResult2 =
          runTestFutureException(() => source2.update(testValue));

      expect(await updateResult1, isNotTextException);
      expect(await updateResult2, isNotTextException);
      expect(await runTestFutureException(() => source1.update(testValue)),
          isNotTextException);

      final deleteResult1 = runTestFutureException(() => source1.delete());
      final deleteResult2 = runTestFutureException(() => source2.delete());

      expect(await deleteResult1, isNotTextException);
      expect(await deleteResult2, isNotTextException);
      expect(await runTestFutureException(() => source1.delete()),
          isNotTextException);
    });
  });
}
