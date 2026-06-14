import 'dart:async';

import 'package:meta/meta.dart';

import 'package:storage_sources_core/storage_sources_core.dart';
import '../storage_sources_sql_core.dart';

abstract class SingleTableSqliteStorageSource<T> extends SqliteStorageSource<T>
    implements KeyedDataStorageSource<T> {
  SingleTableSqliteStorageSource();

  DatabaseTableStatePublic get dbTableStatePublic =>
      dbTableState as DatabaseTableStatePublic;

  @protected
  DatabaseTableState get dbTableState;

  @override
  @protected
  DatabaseState get dbState => dbTableState.dbState;

  /// Return id of inserted of updated value;
  @override
  FutureOr<int> update(T newData);

  /// Return number of rows affected
  @override
  FutureOr<int> delete();
}

abstract class SingleTableSqliteStorageSourceProxy<T, ProxyType,
        ProxySource extends SingleTableSqliteStorageSource<ProxyType>>
    extends SqliteStorageSourceProxy<T, ProxyType, ProxySource>
    implements SingleTableSqliteStorageSource<T> {
  @override
  String get key => parent.key;

  @override
  DatabaseTableStatePublic get dbTableStatePublic => parent.dbTableState;

  @override
  @protected
  DatabaseTableState get dbTableState => parent.dbTableState;
}
