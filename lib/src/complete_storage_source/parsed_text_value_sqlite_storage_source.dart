import 'package:storage_sources_core/storage_sources.dart';
import '../../storage_sources_sql.dart';

class ParsedTextValueSqliteStorageSource<T>
    extends ModifiableStorageSourceConverter<T, String?,
        TextValueSqliteStorageSource> {
  ParsedTextValueSqliteStorageSource({
    required super.parent,
    required T Function(String? value) fromStringConverter,
    required String? Function(T value) toStringConverter,
  }) : super(
          converter: (futureData) async {
            if (futureData case SR<String?> data) {
              return data.convert(fromStringConverter);
            }

            final data = await futureData;
            return data.convert(fromStringConverter);
          },
          updateConverter: toStringConverter,
        );
}
