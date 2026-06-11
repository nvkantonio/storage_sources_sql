import 'package:meta/meta.dart';
import 'package:storage_sources_core/storage_sources.dart';

import '../storage_sources_sql_core.dart';

abstract class SqliteStorageSource<T> implements DatabaseStorageSource<T> {
  SqliteStorageSource();

  @protected
  DatabaseState get dbState;
}

abstract class SqliteStorageSourceProxy<T, ProxyType,
        ProxySource extends SqliteStorageSource<ProxyType>>
    extends ModifiableDataStorageSourceProxy<T, ProxyType, ProxySource>
    implements SqliteStorageSource<T> {
  @override
  @protected
  DatabaseState get dbState => parent.dbState;
}
