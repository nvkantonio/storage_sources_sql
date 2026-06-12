import 'dart:io' as io;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:storage_sources_core/misc.dart';
import 'package:storage_sources_core/storage_sources.dart';

import 'package:storage_sources_sql/storage_sources_sql.dart';
import 'package:test/test.dart';

typedef OkResponse<T> = OkStorageSourceResult<T>;
typedef UndefResponse<T> = UndefinedStorageSourceResult<T>;
typedef ErrorResponse<T> = ErrorStorageSourceResult<T>;

void main() {
  if (!io.Platform.isAndroid || !io.Platform.isIOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  group('A group of CacheOrHeadmostStorage update tests', () {
    const testValue1 = 'testValue1';
    const testValue2 = 'testValue2';

    String callbackValue = testValue1;

    final dbState = DatabaseStateInMemory();

    final dbSource = TextValueSqliteStorageSource(
      dbState: dbState,
      key: 'test-key',
    );

    final storage = CacheOrHeadmostStorage<String?>(
      cacheSource: dbSource,
      headmostSource: CallbackStorageSource(() => callbackValue),
      behavior: CacheOrHeadmostStorageBehavior(
        runTasksImmediately: true,
        runHeadmostSourceFirst: true,
        doRunSecondIfFirstOk: true,
        deleteCacheOnError: true,
        updateCacheIfNotEqual: true,
      ),
    );

    setUp(() async {
      await dbState.openDatabase();
    });

    tearDown(() async {
      await dbState.forceCloseDatabase();
      dbSource.dbTableStatePublic.clearIsTableExistState();
    });

    test('Test db value empty initially', () async {
      expect(await storage.dataStream().toList(),
          [UndefResponse<String?>(), OkResponse<String?>(testValue1)]);
    });

    test('Test db value insert value', () async {
      expect(await storage.dataStream().toList(),
          [UndefResponse<String?>(), OkResponse<String?>(testValue1)]);

      // Test db value created in storage process
      expect(await storage.dataStream().toList(), [
        OkResponse<String?>(testValue1),
        OkResponse<String?>(testValue1),
      ]);
    });

    test('Test db value replace value', () async {
      expect(await storage.dataStream().toList(),
          [UndefResponse<String?>(), OkResponse<String?>(testValue1)]);

      // Test db value created in storage process
      expect(await storage.dataStream().toList(), [
        OkResponse<String?>(testValue1),
        OkResponse<String?>(testValue1),
      ]);

      // Test db value update
      callbackValue = testValue2;

      expect(await storage.dataStream().toList(), [
        OkResponse<String?>(testValue1),
        OkResponse<String?>(testValue2),
      ]);

      expect(await storage.dataStream().toList(), [
        OkResponse<String?>(testValue2),
        OkResponse<String?>(testValue2),
      ]);
    });
  });

  group('A group of CacheOrHeadmostStorage update with delayed callback tests',
      () {
    const testValue1 = 'testValue1';
    const testValue2 = 'testValue2';

    String callbackValue = testValue1;

    final dbState = DatabaseStateInMemory();

    final dbSource = TextValueSqliteStorageSource(
      dbState: dbState,
      key: 'test-key',
    );

    final storage = CacheOrHeadmostStorage<String?>(
      cacheSource: dbSource,
      headmostSource: CallbackStorageSource(
        () => Future.delayed(
          Duration(milliseconds: 20),
          () => callbackValue,
        ),
      ),
      behavior: CacheOrHeadmostStorageBehavior(
        runTasksImmediately: true,
        runHeadmostSourceFirst: true,
        doRunSecondIfFirstOk: true,
        deleteCacheOnError: true,
        updateCacheIfNotEqual: true,
      ),
    );

    setUp(() async {
      await dbState.openDatabase();
    });

    tearDown(() async {
      await dbState.forceCloseDatabase();
      dbSource.dbTableStatePublic.clearIsTableExistState();
    });

    test('Test db value insert value with delayed callback', () async {
      expect(await storage.dataStream().toList(),
          [UndefResponse<String?>(), OkResponse<String?>(testValue1)]);

      // Test db value created in storage process
      expect(await storage.dataStream().toList(), [
        OkResponse<String?>(testValue1),
        OkResponse<String?>(testValue1),
      ]);
    });

    test('Test db value replace value with delayed callback', () async {
      expect(await storage.dataStream().toList(),
          [UndefResponse<String?>(), OkResponse<String?>(testValue1)]);

      // Test db value created in storage process
      expect(await storage.dataStream().toList(), [
        OkResponse<String?>(testValue1),
        OkResponse<String?>(testValue1),
      ]);

      // Test db value update
      callbackValue = testValue2;

      expect(await storage.dataStream().toList(), [
        OkResponse<String?>(testValue1),
        OkResponse<String?>(testValue2),
      ]);

      expect(await storage.dataStream().toList(), [
        OkResponse<String?>(testValue2),
        OkResponse<String?>(testValue2),
      ]);
    });
  });

  group('A group of CacheOrHeadmostStorage source exceptions tests', () {
    final dbState = DatabaseStateInMemory();

    String converterTestNull(String? value) {
      if (value == null) {
        throw 'Conversion exception';
      } else {
        return value;
      }
    }

    String? okCallbackFn() => 'testValue';
    String? causeConversionErrorFn() => null;
    Never errorCallbackFn() => throw 'Forced exception';

    String? Function() callbackFn = errorCallbackFn;

    final dbSource = TextValueConvertibleSqliteStorageSource<String?>(
      dbState: dbState,
      key: 'test-key',
      fromStringConverter: converterTestNull,
      toStringConverter: converterTestNull,
    );

    final storage = CacheOrHeadmostStorage<String?>(
      cacheSource: dbSource,
      headmostSource: CallbackStorageSource(() => callbackFn()),
      behavior: CacheOrHeadmostStorageBehavior(
        runTasksImmediately: true,
        runHeadmostSourceFirst: true,
        doRunSecondIfFirstOk: true,
        deleteCacheOnError: true,
        updateCacheIfNotEqual: true,
      ),
    );

    setUp(() async {
      callbackFn = errorCallbackFn;
      await dbState.openDatabase();
    });

    tearDown(() async {
      await dbState.forceCloseDatabase();
      dbSource.dbTableStatePublic.clearIsTableExistState();
    });

    /// Update dbSource value which will throw
    Future<void> updateDbValueToInvalid() async {
      await dbState.runInIsolate((db) async {
        await dbSource.updateDirect({
          TextValueConvertibleSqliteStorageSource.keyColumnName: 'test-key',
          TextValueConvertibleSqliteStorageSource.dataColumnName:
              causeConversionErrorFn(),
        }, db);
      });
    }

    test(
      'Test dbSource value must not update on invalid callbackSource',
      () async {
        expect(await storage.dataStream().toList(), [
          isA<UndefResponse<String?>>(),
          isA<ErrorResponse<String?>>(),
        ]);

        /// Expect dbSource value didn't change
        expect(await dbSource.fetchData(), isA<UndefResponse<String?>>());
      },
    );

    test(
      'Test dbSource value must be deleted on invalid db value and invalid callbackSource',
      () async {
        await updateDbValueToInvalid();

        expect(await storage.dataStream().toList(), [
          isA<ErrorResponse<String?>>(),
          isA<ErrorResponse<String?>>(),
        ]);

        /// Expect dbSource invalid value was deleted
        expect(await dbSource.fetchData(), isA<UndefResponse<String?>>());
      },
    );

    test(
      'Test dbSource value must be updated on invalid db value and valid callbackSource',
      () async {
        callbackFn = okCallbackFn;

        await updateDbValueToInvalid();

        expect(await storage.dataStream().toList(),
            [isA<ErrorResponse<String?>>(), isA<OkResponse<String?>>()]);

        /// Expect dbSource invalid value was replaced with valid data
        expect(await dbSource.fetchData(), isA<OkResponse<String?>>());
      },
    );

    test(
      'Test dbSource value must not change on valid db value and invalid callbackSource',
      () async {
        await dbSource.update(okCallbackFn());

        expect(await storage.dataStream().toList(),
            [isA<OkResponse<String?>>(), isA<ErrorResponse<String?>>()]);

        /// Expect dbSource invalid value was not changed
        expect(await dbSource.fetchData(), isA<OkResponse<String?>>());
      },
    );

    test(
      'Test dbSource value post task value parsing on invalid value must throw',
      () async {
        callbackFn = causeConversionErrorFn;

        await dbSource.update(okCallbackFn());

        expect(await storage.dataStream().toList(), [
          OkResponse<String?>(okCallbackFn()),
          OkResponse<String?>(causeConversionErrorFn()),
          isA<OtherErrorStorageSourceResult<String?>>()
        ]);
      },
    );
  });
}
