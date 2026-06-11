import '../../storage_sources_sql.dart';

class PathValueSqliteStorageSource
    extends RegularSingleTableSqliteStorageSource<String> {
  PathValueSqliteStorageSource({required super.key, required super.dbState});

  @override
  String get tableName => kTableName;

  @override
  String get createTableQuery => kCreateTableQuery;

  @override
  String dataFromDatabaseRow(Map<String, Object?> result) {
    return result[dataColumnName] as String;
  }

  @override
  Map<String, Object?> databaseRowFromData(String data) {
    return {keyColumnName: key, dataColumnName: data};
  }

  static const kTableName = 'path_value_table';
  static const keyColumnName = 'key';
  static const dataColumnName = 'path';

  static const kCreateTableQuery = '''
CREATE TABLE IF NOT EXISTS $kTableName (
    id INTEGER PRIMARY KEY,
    $keyColumnName TEXT NOT NULL UNIQUE,
    $dataColumnName TEXT
);
  ''';
}
