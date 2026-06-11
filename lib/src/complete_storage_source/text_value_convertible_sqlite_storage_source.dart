import '../../storage_sources_sql.dart';

typedef JsonObject = List<Map<String, Object?>>;

class TextValueConvertibleSqliteStorageSource<T>
    extends RegularSingleTableSqliteStorageSource<T> {
  TextValueConvertibleSqliteStorageSource({
    required super.key,
    required super.dbState,
    required this.fromStringConverter,
    required this.toStringConverter,
  });

  @override
  String get tableName => kTableName;

  final T Function(String? value) fromStringConverter;
  final String Function(T value) toStringConverter;

  @override
  String get createTableQuery => kCreateTableQuery;

  @override
  T dataFromDatabaseRow(Map<String, Object?> result) {
    final data = result[dataColumnName] as String?;
    return fromStringConverter(data);
  }

  @override
  Map<String, Object?> databaseRowFromData(T data) {
    return {keyColumnName: key, dataColumnName: toStringConverter(data)};
  }

  static const kTableName = 'text_value_table';
  static const keyColumnName = 'key';
  static const dataColumnName = 'details';

  static const kCreateTableQuery = '''
CREATE TABLE IF NOT EXISTS $kTableName (
    id INTEGER PRIMARY KEY,
    $keyColumnName TEXT NOT NULL UNIQUE,
    $dataColumnName TEXT
);
  ''';
}
