import 'dart:async';
import 'dart:io' as io;

import 'package:path/path.dart' as path_lib;
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

void main() {
  if (!io.Platform.isAndroid || !io.Platform.isIOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  const testValue1 = 'testValue1';
  const testValue2 = 'testValue2';
  const processLink1 = 'processLink1';
  const processLink2 = 'processLink2';
  const key1 = 'key1';
  const key2 = 'key2';

  Future<void> millisecondDelay() => Future.delayed(Duration(milliseconds: 1));

  Future<String> futureValue1(Database db) => Future.delayed(
        Duration(milliseconds: 10),
        () => testValue1,
      );
  Future<String> futureValue2(Database db) => Future.delayed(
        Duration(milliseconds: 10),
        () => testValue2,
      );

  group('A group of DatabaseStateCallback tests', () {
    final testingDirectoryPath = path_lib.join(path_lib.current, 'test_folder');

    final dbPath = path_lib.join(testingDirectoryPath, 'temp_db.db');
    final testingDbFile = io.File(dbPath);

    final dbState =
        DatabaseStateCallback(() => databaseFactoryFfi.openDatabase(dbPath));

    final completers = dbState.databaseProcessLocker.completersHashMap;
    FutureOr<Database>? getDatabase() => dbState.databaseProcessLocker.database;

    setUp(() async {
      await dbState.openDatabase();
    });

    tearDown(() async {
      await dbState.closeDatabase();
    });

    setUpAll(
      () async {
        if (await testingDbFile.exists()) {
          await testingDbFile.delete();
        }
      },
    );

    tearDownAll(
      () async {
        final testingDirectory = io.Directory(testingDirectoryPath);

        if (await testingDbFile.exists()) {
          await testingDbFile.delete();
        }

        if (await testingDirectory.exists()) {
          await testingDirectory.delete();
        }
      },
    );

    test('Test DatabaseStateCallback. Equal process. Equal key', () async {
      final res1Pr1 = Future(
        () => dbState.runInMultiProcessIsolate(
          futureValue1,
          processLink: processLink1,
          equalityArg: key1,
        ),
      );
      final res2Pr1 = Future(
        () => dbState.runInMultiProcessIsolate(
          futureValue2,
          processLink: processLink1,
          equalityArg: key1,
        ),
      );

      await millisecondDelay();
      expect(completers, isNotEmpty);
      expect((await getDatabase())?.isOpen, true);

      expect(await res1Pr1, testValue1);
      expect(completers, isEmpty);
      expect(await res2Pr1, testValue1);
      expect(completers, isEmpty);

      await millisecondDelay();
      expect((await getDatabase())?.isOpen, null);
    });

    test('Test DatabaseStateCallback. Equal process. Unequal key', () async {
      final res1Pr1 = Future(
        () => dbState.runInMultiProcessIsolate(
          futureValue1,
          processLink: processLink1,
          equalityArg: key1,
        ),
      );
      final res2Pr1 = Future(
        () => dbState.runInMultiProcessIsolate(
          futureValue2,
          processLink: processLink1,
          equalityArg: key2,
        ),
      );

      await millisecondDelay();
      expect(completers, isNotEmpty);
      expect((await getDatabase())?.isOpen, true);

      expect(await res1Pr1, testValue1);
      expect(await res2Pr1, testValue2);

      expect(completers, isEmpty);

      await millisecondDelay();
      expect((await getDatabase())?.isOpen, null);
    });

    test('Test DatabaseStateCallback. Unequal process. Equal key', () async {
      final res1Pr1 = Future(
        () => dbState.runInMultiProcessIsolate(
          futureValue1,
          processLink: processLink1,
          equalityArg: key1,
        ),
      );
      final res2Pr1 = Future(
        () => dbState.runInMultiProcessIsolate(
          futureValue2,
          processLink: processLink2,
          equalityArg: key1,
        ),
      );

      await millisecondDelay();
      expect(completers, isNotEmpty);
      expect((await getDatabase())?.isOpen, true);
      expect(completers.length, 2);

      expect(await res1Pr1, testValue1);
      expect(await res2Pr1, testValue2);

      expect(completers, isEmpty);

      await millisecondDelay();
      expect((await getDatabase())?.isOpen, null);
    });

    test('Test DatabaseStateCallback. Unequal process. Unequal key', () async {
      final res1Pr1 = Future(
        () => dbState.runInMultiProcessIsolate(
          futureValue1,
          processLink: processLink1,
          equalityArg: key1,
        ),
      );
      final res2Pr1 = Future(
        () => dbState.runInMultiProcessIsolate(
          futureValue2,
          processLink: processLink2,
          equalityArg: key2,
        ),
      );

      await millisecondDelay();
      expect(completers, isNotEmpty);
      expect((await getDatabase())?.isOpen, true);
      expect(completers.length, 2);

      expect(await res1Pr1, testValue1);
      expect(await res2Pr1, testValue2);

      expect(completers, isEmpty);

      await millisecondDelay();
      expect((await getDatabase())?.isOpen, null);
    });
  });
}
