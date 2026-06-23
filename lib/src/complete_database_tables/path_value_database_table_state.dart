import 'package:storage_sources_sql/storage_sources_sql.dart';

final class PathValueDatabaseTableState extends KeyValueDatabaseTableState {
  PathValueDatabaseTableState(this.dbState);

  @override
  final DatabaseState dbState;

  @override
  String get keyColumnName => kKeyColumnName;

  @override
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
