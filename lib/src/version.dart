// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://github.com/vsergeev/c-periphery/blob/master/src/version.c
// https://github.com/vsergeev/c-periphery/blob/master/src/version.h
// https://github.com/dart-lang/samples/tree/master/ffi

import 'package:ffi/ffi.dart';
import 'signature.dart';

// const char *dart_periphery_version_info()
final _nativeVersion = utf8VOIDM('periphery_version');

/// Returns the version of the native
/// [c-periphery](https://github.com/vsergeev/c-periphery/blob/master/src/version.c)
/// library.
String getCperipheryVersion() {
  return _nativeVersion().toDartString();
}

/// dart_periphery version
const String dartPeripheryVersion = '0.9.12';
