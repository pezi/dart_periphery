// pub global activate --source path dart_periphery
// pub global run dart_periphery:build_lib

import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart';

const pkgName = 'dart_periphery';

class PlatformException implements Exception {
  String error;
  @override
  String toString() => error;
  PlatformException(this.error);
}

/// Build a file path.
String toFilePath(String parent, String path, {bool windows}) {
  var uri = Uri.parse(path);
  path = uri.toFilePath(windows: windows);
  if (isRelative(path)) {
    return normalize(join(parent, path));
  }
  return normalize(path);
}

/// Find our package path in the current project
String findPackagePath(String currentPath, {bool windows}) {
  String findPath(File file) {
    var lines = LineSplitter.split(file.readAsStringSync());
    for (var line in lines) {
      var parts = line.split(':');
      if (parts.length > 1) {
        if (parts[0] == pkgName) {
          var location = parts.sublist(1).join(':');
          return absolute(normalize(
              toFilePath(dirname(file.path), location, windows: windows)));
        }
      }
    }
    return null;
  }

  var file = File(join(currentPath, '.packages'));
  if (file.existsSync()) {
    return findPath(file);
  } else {
    var parent = dirname(currentPath);
    if (parent == currentPath) {
      throw PlatformException('Unable to resolve ' + currentPath);
    }
    return findPackagePath(parent);
  }
}

void main() {
  if (!Platform.isLinux) {
    throw PlatformException('dart_periphery is only supported on Linux');
  }

  var location = findPackagePath(Directory.current.path);
  var path = normalize(join(location, 'src', 'native'));

  Process.run('./build.sh', [], workingDirectory: path)
      .then((ProcessResult results) {
    print(results.stdout);
  });
}
