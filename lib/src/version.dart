// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://github.com/vsergeev/c-periphery/blob/master/src/version.c
// https://github.com/vsergeev/c-periphery/blob/master/src/version.h
// https://github.com/dart-lang/samples/tree/master/ffi

import 'dart:ffi';
import 'library.dart';
import 'package:ffi/ffi.dart';

final DynamicLibrary _peripheryLib = getPeripheryLib();

// const char *dart_periphery_version_info()
typedef _dart_periphery_version_info = Pointer<Utf8> Function();
typedef _PeripheryVersion = Pointer<Utf8> Function();
final _nativeVersion = _peripheryLib
    .lookup<NativeFunction<_dart_periphery_version_info>>('periphery_version')
    .asFunction<_PeripheryVersion>();

/// Returns the c-periphery version.
String getCperipheryVersion() {
  return Utf8.fromUtf8(_nativeVersion());
}
