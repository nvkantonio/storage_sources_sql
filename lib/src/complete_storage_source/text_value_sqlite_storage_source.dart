import '../../storage_sources_sql.dart';

final class TextValueDatabaseTableState extends DatabaseTableStateBase {
  TextValueDatabaseTableState(this.dbState);

  @override
  final DatabaseState dbState;

  String get keyColumnName => kKeyColumnName;
  String get dataColumnName => kDataColumnName;

  @override
  String get tableName => kTableName;

  @override
  String get createTableQuery => kCreateTableQuery;

  static const kTableName = 'text_value_table';
  static const kKeyColumnName = 'key';
  static const kDataColumnName = 'details';

  static const kCreateTableQuery = '''
CREATE TABLE IF NOT EXISTS $kTableName (
    id INTEGER PRIMARY KEY,
    $kKeyColumnName TEXT NOT NULL UNIQUE,
    $kDataColumnName TEXT
);
  ''';
}

class TextValueSqliteStorageSource
    extends RegularSingleTableSqliteStorageSource<String?> {
  TextValueSqliteStorageSource({required this.key, required this.dbTableState});

  @override
  final String key;

  @override
  final TextValueDatabaseTableState dbTableState;

  @override
  String? dataFromDatabaseRow(Map<String, Object?> result) {
    return result[dbTableState.dataColumnName] as String?;
  }

  @override
  Map<String, Object?> databaseRowFromData(String? data) {
    return {dbTableState.keyColumnName: key, dbTableState.dataColumnName: data};
  }
}
