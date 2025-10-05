// Copyright (c) 2022,2025 the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'json.dart';

import 'package:dart_periphery/src/isolate_api.dart';
import 'dart:ffi';

/// Dummy sensor for development.
class DummyDev implements IsolateAPI {
  static int handleCounter = 1;
  Pointer<Void> _dummyHandle;
  final bool isolate;

  DummyDev()
      : _dummyHandle = Pointer.fromAddress(handleCounter++),
        isolate = false;

  @override
  IsolateAPI fromJson(String json) {
    return DummyDev();
  }

  @override
  int getHandle() {
    return _dummyHandle.address;
  }

  @override
  void setHandle(int handle) {
    _dummyHandle = Pointer<Void>.fromAddress(handle);
  }

  @override
  String toJson() {
    return '{"class":"DummyDev","handle":${_dummyHandle.address}}';
  }

  int add(int a, int b) {
    return a + b;
  }

  DummyDev.isolate(String json)
      : _dummyHandle =
            Pointer<Void>.fromAddress(jsonMap(json)['handle'] as int),
        isolate = true;

  void dispose() {}

  @override
  bool isIsolate() {
    return isolate;
  }
}
