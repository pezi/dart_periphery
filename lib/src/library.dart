// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:system_info/system_info.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart';
import 'version.dart';

const pkgName = 'dart_periphery';

const String version = '1.0.0';

String staticLib =
    'dart_periphery_static_${SysInfo.userSpaceBitness}.$version.so';
String sharedLib = 'dart_periphery_${SysInfo.userSpaceBitness}.$version.so';

String library = staticLib;

late DynamicLibrary _peripheryLib;
bool isPeripheryLibLoaded = false;
String _peripheryLibPath = '';

/// Build a file path.
String toFilePath(String parent, String path, {bool windows = false}) {
  var uri = Uri.parse(path);
  path = uri.toFilePath(windows: windows);
  if (isRelative(path)) {
    return normalize(join(parent, path));
  }
  return normalize(path);
}

/// Find our package path in the current project
String findPackagePath(String currentPath, {bool windows = false}) {
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
    return '';
  }

  var file = File(join(currentPath, '.packages'));
  if (file.existsSync()) {
    return findPath(file);
  } else {
    var parent = dirname(currentPath);
    if (parent == currentPath) {
      return '';
    }
    return findPackagePath(parent);
  }
}

class PlatformException implements Exception {
  @override
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
void useLocalLibrary([bool staticLibFlag = true]) {
  _peripheryLibPath = './' + (!staticLibFlag ? sharedLib : staticLib);
}

enum LibraryErrorCode { LIBRARY_NOT_FOUND, LIBRARY_VERSION_MISMATCH }

/// Library exception
class LibraryException implements Exception {
  final String errorMsg;
  final LibraryErrorCode errorCode;
  LibraryException(this.errorCode, this.errorMsg);
  @override
  String toString() => errorMsg;
}

typedef _dart_periphery_version_info = Pointer<Utf8> Function();
typedef _PeripheryVersion = Pointer<Utf8> Function();

DynamicLibrary getPeripheryLib() {
  if (!Platform.isLinux) {
    throw PlatformException();
  }
  if (isPeripheryLibLoaded) {
    return _peripheryLib;
  }
  String path;
  if (_peripheryLibPath.isNotEmpty) {
    path = _peripheryLibPath;
  } else {
    var location = findPackagePath(Directory.current.path);
    if (location.isEmpty) {
      throw LibraryException(LibraryErrorCode.LIBRARY_NOT_FOUND,
          "Unable to find native lib '$library'. Non standard environment e.g. flutter-pi? Use 'setCustomLibrary(String absolutePath)' - see documentation https://github.com/pezi/dart_periphery, or create an issue https://github.com/pezi/dart_periphery/issues");
    }
    path = normalize(join(location, 'src', 'native', library));
  }
  _peripheryLib = DynamicLibrary.open(path.toString());

  var _internalVersion = _peripheryLib
      .lookup<NativeFunction<_dart_periphery_version_info>>('dart_get_version')
      .asFunction<_PeripheryVersion>();
  var glueLibVer = _internalVersion().toDartString();

  if (glueLibVer != DART_PERIPHERY_GLUE_LIBVERSION) {
    throw LibraryException(LibraryErrorCode.LIBRARY_VERSION_MISMATCH,
        'Version native lib $glueLibVer != Dart package version $DART_PERIPHERY_GLUE_LIBVERSION');
  }
  isPeripheryLibLoaded = true;
  return _peripheryLib;
}
