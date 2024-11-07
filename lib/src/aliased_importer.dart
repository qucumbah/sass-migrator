import 'package:path/path.dart' as p;

import 'package:sass_api/sass_api.dart';
import 'package:sass_migrator/src/utils.dart';

class AliasedImporter extends Importer {
  final String? _loadPath;

  final Map<String, String> aliases;

  final FilesystemImporter _filesystemImporter;

  AliasedImporter(String loadPath, Map<String, String> aliases)
      : _loadPath = p.absolute(loadPath),
        aliases = aliases,
        _filesystemImporter = FilesystemImporter(loadPath);

  Uri pathAfterReplacement(Uri url) {
    var cleanedAliases = aliases.map((key, value) =>
        MapEntry(replaceLast(key, "*", ""), replaceLast(value, "*", "")));

    print(cleanedAliases);

    for (var entry in cleanedAliases.entries) {
      if (url.toString().startsWith(entry.key)) {
        var afterReplacement =
            p.fromUri(url).replaceFirst(entry.key, entry.value);
        var result =
            p.join(p.fromUri(_loadPath), p.normalize(afterReplacement));
        print(result);
        return p.toUri(result);
      }
    }

    return url;
  }

  Uri? canonicalize(Uri url) {
    return _filesystemImporter.canonicalize(pathAfterReplacement(url));
  }

  /// Loads [url] using a [FilesystemImporter].
  ///
  /// [url] must be the canonical URL returned by [canonicalize].
  ImporterResult? load(Uri url) => _filesystemImporter.load(url);
}
