import '../../storage_sources_sql.dart';

class TextValueConvertibleSqliteStorageSource<T>
    extends RegularSingleTableSqliteStorageSource<T> {
  TextValueConvertibleSqliteStorageSource({
    required this.key,
    required this.dbTableState,
    required this.fromStringConverter,
    required this.toStringConverter,
  });

  @override
  final String key;

  @override
  final KeyValueDatabaseTableState dbTableState;

  final T Function(String? value) fromStringConverter;
  final String Function(T value) toStringConverter;

  @override
  T dataFromDatabaseRow(Map<String, Object?> result) {
    final data = result[dbTableState.dataColumnName] as String?;
    return fromStringConverter(data);
  }

  @override
  Map<String, Object?> databaseRowFromData(T data) {
    return {
      dbTableState.keyColumnName: key,
      dbTableState.dataColumnName: toStringConverter(data)
    };
  }
}
