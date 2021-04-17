// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:system_info/system_info.dart';
import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart';
import 'dart:typed_data';

const pkgName = 'dart_periphery';

const String version = '1.0.0';
final String arch = SysInfo.processors[0].architecture.name;
// final String arch = SysInfo.kernelArchitecture;
final String prebuildLib = 'libperiphery_${arch.toLowerCase()}.so';
final String sharedLib = 'libperiphery.so';

String library = prebuildLib;

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
  final String error;
  PlatformException(this.error);
  @override
  String toString() => error;
}

/// dart_periphery loads the shared library.
/// See [native-libraries](https://pub.dev/packages/dart_periphery#native-libraries) for details.
void useSharedLibray() {
  library = sharedLib;
}

/// dart_periphery loads a custom library.
/// See [native-libraries](https://pub.dev/packages/dart_periphery#native-libraries) for details.
void setCustomLibrary(String absolutePath) {
  _peripheryLibPath = absolutePath;
}

/// dart_periphery loads the library from the actual directory.
/// See [native-libraries](https://pub.dev/packages/dart_periphery#native-libraries) for details.
void useLocalLibrary() {
  _peripheryLibPath = './' + prebuildLib;
}

enum LibraryErrorCode { LIBRARY_NOT_FOUND }

/// Library exception
class LibraryException implements Exception {
  final String errorMsg;
  final LibraryErrorCode errorCode;
  LibraryException(this.errorCode, this.errorMsg);
  @override
  String toString() => errorMsg;
}

typedef _getpId = Int32 Function();
typedef _GetpId = int Function();

bool _isFutterPi = Platform.resolvedExecutable.endsWith('flutter-pi');

bool isFutterPiEnv() {
  return _isFutterPi;
}

var _flutterPiArgs = <String>[];

List<String> getFlutterPiArgs() {
  if (!isFutterPiEnv()) {
    return const <String>[];
  }
  if (_flutterPiArgs.isEmpty) {
    final dylib = DynamicLibrary.open('libc.so.6');
    var getpid =
        dylib.lookup<NativeFunction<_getpId>>('getpid').asFunction<_GetpId>();
    var cmd = File('/proc/${getpid()}/cmdline').readAsBytesSync();
    var index = 0;
    for (var i = 0; i < cmd.length; ++i) {
      if (cmd[i] == 0) {
        _flutterPiArgs
            .add(String.fromCharCodes(Uint8List.sublistView(cmd, index, i)));
        index = i + 1;
      }
    }
  }
  return List.unmodifiable(_flutterPiArgs);
}

DynamicLibrary getPeripheryLib() {
  if (isPeripheryLibLoaded) {
    return _peripheryLib;
  }
  if (!Platform.isLinux) {
    throw PlatformException('dart_periphery is only supported for Linux!');
  }
  var supportEnv = false;
  if (arch == ProcessorArchitecture.ARM.name) {
    supportEnv = true;
  } else if (arch == ProcessorArchitecture.AARCH64.name) {
    supportEnv = true;
  } else if (arch == ProcessorArchitecture.X86.name) {
    supportEnv = true;
  } else if (arch == ProcessorArchitecture.X86_64.name) {
    supportEnv = true;
  }
  if (!supportEnv) {
    throw PlatformException(
        'No pre-build c-periphery library for $arch available!');
  }

  String path;
  if (isFutterPiEnv()) {
    var args = getFlutterPiArgs();
    var index = 1;
    for (var i = 1; i < args.length; ++i) {
      // skip --release
      if (args[i].startsWith('--release')) {
        ++index;
        // skip optione like -r, --rotation <degrees>
      } else if (args[i].startsWith('-')) {
        index += 2;
      } else {
        break;
      }
    }
    var assetDir = args[index];
    var separator = '';
    if (!assetDir.startsWith('/')) {
      separator = '/';
    }
    var dir = Directory.current.path + separator + assetDir;
    if (!dir.endsWith('/')) {
      dir += '/';
    }
    path = dir + library;
  } else if (_peripheryLibPath.isNotEmpty) {
    path = _peripheryLibPath;
  } else {
    var location = findPackagePath(Directory.current.path);
    if (location.isEmpty) {
      throw LibraryException(LibraryErrorCode.LIBRARY_NOT_FOUND,
          "Unable to find native lib '$library'. Non standard environment. Use 'setCustomLibrary(String absolutePath)' - see documentation https://github.com/pezi/dart_periphery, or create an issue https://github.com/pezi/dart_periphery/issues");
    }
    path = normalize(join(location, 'src', 'native', library));
  }

  if (FileSystemEntity.typeSync(path) == FileSystemEntityType.notFound) {
    throw LibraryException(LibraryErrorCode.LIBRARY_NOT_FOUND,
        "Unable to find native lib '$path'");
  }

  _peripheryLib = DynamicLibrary.open(path);

  isPeripheryLibLoaded = true;
  return _peripheryLib;
}

// var is64Bitsystem = SysInfo.userSpaceBitness == 64;
