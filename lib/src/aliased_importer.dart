// Copyright 2019 Google LLC
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

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

  /// An importer that resolves URLs starting with alias prefixes by
  /// searching in the associated path directories. Returns the first
  /// matching alias.
  ///
  /// This helps migrate codebases heavily reliant on path aliasing,
  /// e.g. next.js codebases with aliases taken from tsconfig.json.
  ///
  /// This method iterates through the [aliases] map and checks if the
  /// [url] starts with any of the keys. If a match is found, it replaces
  /// the key with the corresponding value and returns the modified URL.
  /// If no match is found, the original [url] is returned.
  Uri pathAfterReplacement(Uri url) {
    var cleanedAliases = aliases.map((key, value) =>
        MapEntry(replaceLast(key, "*", ""), replaceLast(value, "*", "")));

    for (var entry in cleanedAliases.entries) {
      if (url.toString().startsWith(entry.key)) {
        var afterReplacement =
            p.fromUri(url).replaceFirst(entry.key, entry.value);
        var result =
            p.join(p.fromUri(_loadPath), p.normalize(afterReplacement));
        return p.toUri(result);
      }
    }

    return url;
  }

  /// This method first processes the [url] through the alias replacement
  /// method to apply alias replacements, and then it canonalizes
  /// the given [url] using the [FilesystemImporter].
  Uri? canonicalize(Uri url) {
    return _filesystemImporter.canonicalize(pathAfterReplacement(url));
  }

  /// Loads the specified [url] using a [FilesystemImporter].
  ///
  /// [url] must be the canonical URL returned by [canonicalize].
  ImporterResult? load(Uri url) => _filesystemImporter.load(url);
}
