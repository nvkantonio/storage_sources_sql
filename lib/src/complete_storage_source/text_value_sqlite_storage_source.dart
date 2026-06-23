import '../../storage_sources_sql.dart';

class TextValueSqliteStorageSource
    extends RegularSingleTableSqliteStorageSource<String?> {
  TextValueSqliteStorageSource({required this.key, required this.dbTableState});

  @override
  final String key;

  @override
  final KeyValueDatabaseTableState dbTableState;

  @override
  String? dataFromDatabaseRow(Map<String, Object?> result) {
    return result[dbTableState.dataColumnName] as String?;
  }

  @override
  Map<String, Object?> databaseRowFromData(String? data) {
    return {dbTableState.keyColumnName: key, dbTableState.dataColumnName: data};
  }
}
