import 'package:storage_sources_sql/storage_sources_sql.dart';

abstract class KeyValueDatabaseTableState extends DatabaseTableStateBase {
  String get keyColumnName;
  String get dataColumnName;
}
