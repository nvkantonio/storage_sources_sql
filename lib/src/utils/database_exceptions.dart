import 'package:storage_sources_core/misc.dart';

class FileWasNotFoundException extends StorageSourceException {
  const FileWasNotFoundException([
    super.message,
    super.source,
    super.stacktrace,
  ]);
}

class KeyMustBeUnique extends StorageSourceException {
  const KeyMustBeUnique([
    super.message,
    super.source,
    super.stacktrace,
  ]);
}

class CanNotCreateTable extends StorageSourceException {
  const CanNotCreateTable([
    super.message,
    super.source,
    super.stacktrace,
  ]);
}

class CanNotOpenDatabase extends StorageSourceException {
  const CanNotOpenDatabase([
    super.message,
    super.source,
    super.stacktrace,
  ]);
}
