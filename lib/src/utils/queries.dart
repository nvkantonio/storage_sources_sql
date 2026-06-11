abstract class Queries {
  static String checkIfTableExistQuery(String table) =>
      '''
  SELECT EXISTS (
    SELECT
        name
    FROM
        sqlite_schema
    WHERE
        type='table' AND
        name='$table'
    );
  ''';

  static String dropTableQuery(String table) =>
      '''
  DROP TABLE [IF EXISTS] $table;
  ''';

  static const whereKey = 'key = ?';
}
