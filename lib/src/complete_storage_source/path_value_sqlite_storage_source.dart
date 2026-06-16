import '../../storage_sources_sql.dart';

final class PathValueDatabaseTableState extends DatabaseTableStateBase {
  PathValueDatabaseTableState(this.dbState);

  @override
  final DatabaseState dbState;

  String get keyColumnName => kKeyColumnName;
  String get dataColumnName => kDataColumnName;

  @override
  String get tableName => kTableName;

  @override
  String get createTableQuery => kCreateTableQuery;

  static const kTableName = 'path_value_table';
  static const kKeyColumnName = 'key';
  static const kDataColumnName = 'path';

  static const kCreateTableQuery = '''
CREATE TABLE IF NOT EXISTS $kTableName (
    id INTEGER PRIMARY KEY,
    $kKeyColumnName TEXT NOT NULL UNIQUE,
    $kDataColumnName TEXT
);
  ''';
}

class PathValueSqliteStorageSource
    extends RegularSingleTableSqliteStorageSource<String> {
  PathValueSqliteStorageSource({required this.key, required this.dbTableState});

  @override
  final String key;

  @override
  final PathValueDatabaseTableState dbTableState;

  @override
  String dataFromDatabaseRow(Map<String, Object?> result) {
    return result[dbTableState.dataColumnName] as String;
  }

  @override
  Map<String, Object?> databaseRowFromData(String data) {
    return {dbTableState.keyColumnName: key, dbTableState.dataColumnName: data};
  }
}
