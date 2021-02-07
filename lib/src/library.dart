import "package:system_info/system_info.dart";
import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'package:ffi/ffi.dart';
import "package:path/path.dart";

const pkgName = 'dart_periphery';

const String version = "1.0.0";

String staticLib =
    'dart_periphery_static_${SysInfo.userSpaceBitness}.${version}.so';
String sharedLib = 'dart_periphery_${SysInfo.userSpaceBitness}.${version}.so';

String library = staticLib;

DynamicLibrary _peripheryLib;
String _peripheryLibPath = "";

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
      return null;
    }
    return findPackagePath(parent);
  }
}

class PlatformException implements Exception {
  String toString() => 'dart_periphery is only supported for Linux';
}

/// dart_periphery loads the shared library.
void useSharedLibray() {
  library = sharedLib;
}

/// dart_periphery loads a custom library.
void setCustomLibrary(String absolutePath) {
  _peripheryLibPath = absolutePath;
}

/// dart_periphery loads the static or the shared library in the actual directory.
void useLocalLibrary([bool staticLib = true]) {
  _peripheryLibPath = './' + (!staticLib ? sharedLib : staticLib);
}

DynamicLibrary getPeripheryLib() {
  if (!Platform.isLinux) {
    throw PlatformException();
  }
  String path;
  if (!_peripheryLibPath.isEmpty) {
    path = _peripheryLibPath;
  } else {
    var location = findPackagePath(Directory.current.path);
    path = normalize(join(location, 'src', 'native', library));
  }

  if (_peripheryLib == null) {
    _peripheryLib = DynamicLibrary.open(path.toString());
  }
  return _peripheryLib;
}
